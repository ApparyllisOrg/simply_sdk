import 'dart:async';
import 'dart:convert';

import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/document.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';

import 'helpers.dart';
import 'simply_sdk.dart';

class Subscription {
  final String target;
  final Map<String, Query> query;
  final StreamController controller;
  List<Document> documents = [];

  Subscription(this.target, this.query, this.controller);
}

class Socket {
  IOWebSocketChannel _socket;
  List<Subscription> _subscriptions = [];
  List<StreamController> pendingSubscriptions = [];
  String uniqueConnectionId;

  void initialize() {
    uniqueConnectionId = Uuid().v4();
    createConnection();
    refreshConnection();
    reconnect();
  }

  void cancelConnections() {
    _subscriptions.clear();
    pendingSubscriptions.clear();
    if (isSocketLive()) {
      _socket.sink.close();
    }
  }

  void reconnect() async {
    if (_subscriptions.isNotEmpty) {
      if (!isSocketLive()) {
        if (_socket != null) {
          print("Socket closed: " +
              _socket.closeCode.toString() +
              _socket.closeReason);
        }
        createConnection();
      }

      if (isSocketLive()) {
        if (pendingSubscriptions.isNotEmpty) {
          StreamController cont = pendingSubscriptions.first;

          Subscription subscription = _subscriptions
              .firstWhere((element) => element.controller == cont);
          requestDataListen(subscription);
          pendingSubscriptions.removeAt(0);
        }
      }
    }

    await Future.delayed(Duration(seconds: 1));
    reconnect();
  }

  bool isSocketLive() => _socket != null && _socket.closeCode == null;
  IOWebSocketChannel getSocket() => _socket;

  void createConnection() {
    _socket = IOWebSocketChannel.connect('wss://api.apparyllis.com:8443',
        pingInterval: Duration(seconds: 10));

    _socket.stream.handleError((err) => print(err));
    _socket.stream.listen(onReceivedData).onError((err) => print(err));

    _socket.sink.done.then((value) => createConnection());

    for (Subscription sub in _subscriptions) {
      pendingSubscriptions.add(sub.controller);
    }
  }

  void updateDocument(
      Subscription sub, Map<String, dynamic> documentData) async {
    var docId = "";
    var docData = sub.documents.firstWhere(
        (element) => element.id == documentData["id"],
        orElse: () => null);
    if (docData != null) {
      docId = docData.id;
      docData.data = Document.convertTime(documentData["content"]);
    } else {
      docId = documentData["id"];
      Document newDoc =
          Document(true, docId, sub.target, documentData["content"]);
      sub.documents.add(newDoc);
    }

    API().cache().updateDocument(sub.target, docId, documentData["content"],
        doTriggerUpdateSubscription: false);
  }

  void removeDocument(Subscription sub, String id) async {
    sub.documents.removeWhere((element) => element.id == id);
    API()
        .cache()
        .removeDocument(sub.target, id, doTriggerUpdateSubscription: false);
  }

  void updateCollectionLocally(Subscription sub, Map<String, dynamic> change) {
    String operation = change["operationType"];

    switch (operation) {
      case "update":
        updateDocument(sub, change);
        return;
      case "insert":
        updateDocument(sub, change);
        return;
      case "delete":
        removeDocument(sub, change["id"]);
        return;
    }
  }

  void beOptimistic(String targetCollection, EUpdateType operation, String id,
      Map<String, dynamic> data) async {
    Map<String, dynamic> sendData = {};
    sendData["operationType"] = updateTypeToString(operation);
    sendData["id"] = id;
    sendData["content"] = data;

    var cacheDoc = await API().cache().getDocument(targetCollection, id);
    if (cacheDoc.exists) {
      Map<String, dynamic> cacheData = cacheDoc.data;
      cacheData.addAll(data);
      sendData["content"] = cacheData;
    }

    await onReceivedData(jsonEncode({
      "msg": "update",
      "target": targetCollection,
      "operationType": updateTypeToString(operation),
      "results": [sendData]
    }, toEncodable: customEncode));
    updateSubscription(targetCollection);
  }

  void updateSubscription(String collection) async {
    for (Subscription sub in _subscriptions) {
      if (sub.target == collection) {
        sub.documents =
            await API().cache().searchForDocuments(collection, {}, "");
        sub.controller.add(sub.documents);
      }
    }
  }

  void onReceivedData(event) async {
    Map<String, dynamic> data = jsonDecode(event, reviver: customDecode);

    String msg = data["msg"];
    print(msg);

    if (msg == "update") {
      for (Subscription sub in _subscriptions) {
        if (sub.controller.isClosed) {
          continue;
        }
        if (sub.target == data["target"]) {
          for (Map<String, dynamic> result in data["results"]) {
            updateCollectionLocally(sub, result);
          }
          sub.controller.add(sub.documents);
          print("received update");
        }
      }
    }
    if (msg == "hello") {
      for (Subscription sub in _subscriptions) {
        if (sub.target == data["target"]) {
          sub.controller.onResume?.call();
        }
      }
    }
  }

  void refreshConnection() async {
    await Future.delayed(Duration(seconds: 10));
    if (!isSocketLive()) {
      createConnection();
    }
    refreshConnection();
  }

  void delayStartOfflineListener(Subscription sub) async {
    await Future.delayed(Duration(milliseconds: 100));
    sub.controller.onResume?.call();
    sub.controller.onListen?.call();

    List<Document> initialDocs =
        await API().cache().searchForDocuments(sub.target, sub.query, "");

    if (sub.documents.isEmpty) {
      sub.documents = initialDocs;
    }

    sub.controller.add(sub.documents);
  }

  Future<StreamController> subscribeToCollection(
      String target, Map<String, Query> query) {
    return Future(() {
      StreamController controller = StreamController();
      Subscription sub = Subscription(target, query, controller);
      _subscriptions.add(sub);
      if (isSocketLive()) {
        pendingSubscriptions.add(sub.controller);
      }
      delayStartOfflineListener(sub);
      return controller;
    });
  }

  void requestDataListen(Subscription subscription) async {
    assert(isSocketLive());
    Map<String, dynamic> queries = {};

    bool hasUid = false;

    subscription.query.forEach((key, value) {
      assert(value != null);
      if (key == "uid") hasUid = true;
      queries[key] = value.getQueryMap();
    });

    // If we aren't requesting the data of someone else, default to our data
    if (!hasUid) {
      queries["uid"] = {"method": "isEqualTo", "value": API().auth().getUid()};
    }

    try {
      _socket.sink.add(jsonEncode({
        "target": subscription.target,
        "jwt": API().auth().getToken(),
        "query": queries,
        "uniqueId": uniqueConnectionId
      }, toEncodable: customEncode));
    } catch (e) {
      print(e);
      _socket.sink.close();
      _socket = null;
      createConnection();
    }
  }
}

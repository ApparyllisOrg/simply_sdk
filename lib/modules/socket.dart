import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers.dart';
import '../simply_sdk.dart';

class Subscription {
  final String target;
  final StreamController controller;
  List<Document> documents = [];

  Subscription(this.target, this.controller);
}

class Socket {
  io.WebSocket? _IOSocket;
  html.WebSocket? _WebSocket;
  List<Subscription> _subscriptions = [];
  List<StreamController> pendingSubscriptions = [];
  late String uniqueConnectionId;

  void bindAuthChanged() {
    API().auth().onAuthChange.add(authChanged);
  }

  void authChanged() {
    sendAuthentication();
  }

  void sendAuthentication() {
    try {
      sendSocketData(jsonEncode({"op": "authenticate", "token": API().auth().getToken()}));
    } catch (e) {}
  }

  void sendSocketData(String data) {
    if (kIsWeb) {
      _WebSocket?.send(data);
    } else {
      _IOSocket?.add(data);
    }
  }

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
      closeSocket();
    }
    if (pingTimer?.isActive == true) {
      pingTimer!.cancel();
      pingTimer = null;
    }
  }

  void reconnect() async {
    if (_subscriptions.isNotEmpty) {
      if (!isSocketLive()) {
        createConnection();
      }

      if (isSocketLive()) {
        if (pendingSubscriptions.isNotEmpty) {
          StreamController cont = pendingSubscriptions.first;

          Subscription subscription = _subscriptions.firstWhere((element) => element.controller == cont);
          requestDataListen(subscription);
          pendingSubscriptions.removeAt(0);
        }
      }
    }

    await Future.delayed(Duration(seconds: 1));
    reconnect();
  }

  Timer? pingTimer;
  bool gotHello = false;
  bool isSocketLive() {
    if (kIsWeb && !html.WebSocket.supported) {
      return false;
    }

    if (kIsWeb) {
      return _WebSocket != null && _WebSocket!.readyState == html.WebSocket.OPEN && gotHello;
    } else {
      return _IOSocket != null && _IOSocket!.closeCode == null && gotHello;
    }
  }

  void closeSocket() {
    if (kIsWeb) {
      _WebSocket?.close();
      _WebSocket = null;
    } else {
      _IOSocket?.close();
      _IOSocket = null;
    }
  }

  bool isDisconnected = true;
  void disconnected() async {
    if (isDisconnected) return;
    isDisconnected = true;

    closeSocket();

    await Future.delayed(Duration(seconds: 1));
    createConnection();
  }

  void createConnection() async {
    if (kIsWeb && !html.WebSocket.supported) {
      return;
    }

    print("Create socket connection");
    gotHello = false;
    isDisconnected = false;
    try {
      String overrideIp = const String.fromEnvironment("WSSIP");
      String socketUrl = overrideIp.isNotEmpty ? overrideIp : 'wss://api.apparyllis.com:8443';

      if (kIsWeb && html.WebSocket.supported) {
        _WebSocket = new html.WebSocket(socketUrl);
      } else {
        _IOSocket = await io.WebSocket.connect(socketUrl, compression: io.CompressionOptions(enabled: true, serverNoContextTakeover: true, clientNoContextTakeover: true, serverMaxWindowBits: 15, clientMaxWindowBits: 15));
      }

      if (kIsWeb && html.WebSocket.supported) {
        _WebSocket!.onError.handleError((err) => disconnected());
        _WebSocket!.onMessage.listen(onData);

        sendAuthentication();

        _WebSocket!.onClose.listen((value) => createConnection());
      } else {
        _IOSocket!.handleError((err) => disconnected());
        _IOSocket!.listen(onData);

        sendAuthentication();

        _IOSocket!.done.then((value) => createConnection());
      }

      if (pingTimer != null && pingTimer!.isActive) {
        pingTimer!.cancel();
      }

      pingTimer = Timer.periodic(Duration(seconds: 10), ping);
    } catch (e) {
      disconnected();
    }

    for (Subscription sub in _subscriptions) {
      pendingSubscriptions.add(sub.controller);
    }
  }

  void ping(Timer timer) {
    if (!isSocketLive()) {
      disconnected();
    }
    try {
      sendSocketData("ping");
    } catch (e) {
      disconnected();
    }
  }

  void updateDocument(Subscription sub, Map<String, dynamic> documentData, String docId) async {
    int docIndex = sub.documents.indexWhere((element) => element.id == docId);

    if (docIndex < 0) {
      DocumentData? data = convertJsonToDataObject(documentData, sub.target);
      if (data != null) {
        Document newDoc = Document(true, docId, data, sub.target);
        sub.documents.add(newDoc);
      }
      docIndex = sub.documents.length - 1;
    }

    Document doc = sub.documents[docIndex];
    doc.data = Document.convertTime(documentData["content"]);
    API().cache().updateDocument(sub.target, docId, documentData["content"], doTriggerUpdateSubscription: false);
  }

  void removeDocument(Subscription sub, String id) async {
    sub.documents.removeWhere((element) => element.id == id);
    API().cache().removeDocument(sub.target, id, doTriggerUpdateSubscription: false);
  }

  void updateCollectionLocally(Subscription sub, Map<String, dynamic> change) {
    String operation = change["operationType"];

    switch (operation) {
      case "update":
        updateDocument(sub, change, change["id"]);
        return;
      case "insert":
        updateDocument(sub, change, change["id"]);
        return;
      case "delete":
        removeDocument(sub, change["id"]);
        return;
    }
  }

  EChangeType operationToChangeType(String operation) {
    switch (operation) {
      case "update":
        return EChangeType.Update;
      case "insert":
        return EChangeType.Add;
      case "delete":
        return EChangeType.Delete;
    }

    return EChangeType.Update;
  }

  void updateSubscription(String collection) async {
    for (Subscription sub in _subscriptions) {
      if (sub.target == collection) {
        /*
        sub.documents =
            await API().cache().searchForDocuments(collection, {}, "");
        sub.controller.add(sub.documents);
        */
      }
    }
  }

  void replayCacheOnCollectionSync(String collection) async {
    var queue = API().cache().getSyncQueue();
    for (Subscription sub in _subscriptions) {
      if (sub.target == collection) {
        for (int i = 0; i < queue.length; i++) {
          var queuedDoc = queue[i];
          if (queuedDoc["collectionRef"] == collection) {
            Logger.root.fine("replaying =>" + queuedDoc["id"]);

            switch (queuedDoc["action"]) {
              case "update":
                updateDocument(sub, {"content": queuedDoc["data"]}, queuedDoc["id"]);
                break;
              case "add": // We use add, they use insert
                updateDocument(sub, {"content": queuedDoc["data"]}, queuedDoc["id"]);
                break;
              case "delete":
                removeDocument(sub, queuedDoc["id"]);
                break;
            }
          }
        }
      }
    }
  }

  void onData(event) {
    gotHello = true;
    Logger.root.fine("[SOCKET DATA RECEIVED] " + event.toString());
    if (event is String && event.isNotEmpty) {
      onReceivedData(event);
    }
  }

  void onReceivedData(event) async {
    Map<String, dynamic> data = jsonDecode(event, reviver: customDecode);

    String? msg = data["msg"];

    if (msg == null) return;

    if (msg == "update") {
      for (Subscription sub in _subscriptions) {
        if (sub.controller.isClosed) {
          continue;
        }
        if (sub.target == data["target"]) {
          bool initial = data["initial"] == true;

          if (initial) {
            // Clear the cache, we may have deleted things while on another phone
            API().cache().clearTypeCache(sub.target);
          }
          for (Map<String, dynamic> result in data["results"]) {
            updateCollectionLocally(sub, result);
            propogateChanges(data["target"], result["id"], result, operationToChangeType(result["operationType"]));
          }

          if (initial) {
            replayCacheOnCollectionSync(sub.target);
          }

          sub.controller.add(sub.documents);
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

    // Todo: Offline search
    /*
    List<Document> initialDocs =
        await API().cache().searchForDocuments(sub.target, sub.query, "");
    if (sub.documents.isEmpty) {
      sub.documents = initialDocs;
    }
    */
    sub.controller.add(sub.documents);
  }

  Future<StreamController> subscribeToCollection(String target, String collection) {
    return Future(() {
      StreamController controller = StreamController();
      Subscription sub = Subscription(target, controller);
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
    try {
      sendSocketData(jsonEncode({"target": subscription.target, "jwt": API().auth().getToken(), "uniqueId": uniqueConnectionId}, toEncodable: customEncode));
    } catch (e) {
      API().reportError(e, StackTrace.current);
      disconnected();
    }
  }
}

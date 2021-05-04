import 'dart:async';
import 'dart:convert';

import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/document.dart';
import 'package:web_socket_channel/io.dart';

class Subscription {
  final String target;
  final String queryField;
  final Query query;
  final StreamController controller;
  List<Document> documents = [];

  Subscription(this.target, this.queryField, this.query, this.controller);
}

class Socket {
  IOWebSocketChannel _socket;
  List<Subscription> _subscriptions = [];

  void initialize() {
    createConnection();
    refreshConnection();
  }

  bool isSocketLive() => _socket != null && _socket.closeCode != null;
  IOWebSocketChannel getSocket() => _socket;

  void createConnection() {
    _socket = IOWebSocketChannel.connect('ws://localhost:8080');

    _socket.stream.listen(onReceivedData);

    for (Subscription sub in _subscriptions) {
      requestDataListen(sub);
    }
  }

  void updateDocument(Subscription sub, Map<String, dynamic> documentData) {
    var docData = sub.documents.firstWhere(
        (element) => element.id == documentData["id"],
        orElse: () => null);
    if (docData != null) {
      docData.data = documentData["content"];
    } else {
      Document newDoc = Document(
          true, documentData["id"], sub.target, documentData["content"]);
      sub.documents.add(newDoc);
    }
  }

  void removeDocument(Subscription sub, String id) {
    sub.documents.removeWhere((element) => element.id == id);
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

  void onReceivedData(event) {
    Map<String, dynamic> data = jsonDecode(event);

    String msg = data["msg"];
    print(msg);
    if (msg == "update") {
      for (Subscription sub in _subscriptions) {
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
          sub.controller.onResume.call();
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

  Future<StreamController> subscribeToCollection(
      String target, String queryField, Query query) {
    return Future(() {
      StreamController controller = StreamController();
      Subscription sub = Subscription(target, queryField, query, controller);
      _subscriptions.add(sub);
      if (isSocketLive()) {
        requestDataListen(sub);
      }
      return controller;
    });
  }

  void requestDataListen(Subscription subscription) {
    assert(_socket != null);
    _socket.sink.add(jsonEncode({
      "target": subscription.target,
      "query": {subscription.queryField: subscription.query.getQueryMap()}
    }));
  }
}

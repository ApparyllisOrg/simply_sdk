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
  List<Document> documents;

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

  void onReceivedData(event) {
    print(event);
    Map<String, dynamic> data = jsonDecode(event);
    for (Subscription sub in _subscriptions) {
      if (sub.target == data["target"]) {
        print(data);
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

  StreamController subscribeToCollection(
      String target, String queryField, Query query) {
    StreamController controller = StreamController();
    Subscription sub = Subscription(target, queryField, query, controller);
    _subscriptions.add(sub);
    if (isSocketLive()) {
      requestDataListen(sub);
    }
    return controller;
  }

  void requestDataListen(Subscription subscription) {
    assert(_socket != null);
    _socket.sink.add(jsonEncode({
      "target": subscription.target,
      "query": {subscription.queryField: subscription.query.getQueryMap()}
    }));
  }
}

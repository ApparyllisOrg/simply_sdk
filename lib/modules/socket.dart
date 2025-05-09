import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/modules/auth.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers.dart';
import '../simply_sdk.dart';

class Socket {
  io.WebSocket? _IOSocket;
  WebSocketChannel? _WebSocket;
  late String uniqueConnectionId;

  final List<void Function(String type, String msg)?> _OnMsgReceived = [];

  void cancelListenForMessages(void Function(String type, String msg) func) {
    _OnMsgReceived.remove(func);
  }

  void listenForMessages(void Function(String type, String msg) func) {
    _OnMsgReceived.add(func);
  }

  void bindAuthChanged() {
    API().auth().onAuthChange.add(authChanged);
  }

  void authChanged(AuthCredentials credentials) {
    sendAuthentication();
  }

  void sendAuthentication() {
    try {
      sendSocketData(jsonEncode({'op': 'authenticate', 'token': API().auth().getToken()}));
    } catch (e) {}
  }

  void sendSocketData(String data) {
    if (kIsWeb) {
      _WebSocket?.sink.add(data);
    } else {
      _IOSocket?.add(data);
    }
  }

  void initialize() {
    uniqueConnectionId = const Uuid().v4();
    createConnection();
    reconnect();
  }

  void cancelConnections() {
    if (isSocketLive()) {
      closeSocket();
    }
    if (pingTimer?.isActive == true) {
      pingTimer!.cancel();
      pingTimer = null;
    }
  }

  Future<void> reconnect() async {
    await Future.delayed(const Duration(seconds: 1));
    reconnect();
  }

  Timer? pingTimer;
  bool gotHello = false;
  bool isSocketLive() {
    if (kIsWeb) {
      return _WebSocket != null && _WebSocket!.closeCode == null && gotHello;
    } else {
      return _IOSocket != null && _IOSocket!.closeCode == null && gotHello;
    }
  }

  void closeSocket() {
    if (kIsWeb) {
      _WebSocket?.sink.close();
      _WebSocket = null;
    } else {
      _IOSocket?.close();
      _IOSocket = null;
    }
  }

  bool isDisconnected = true;
  Future<void> disconnected() async {
    if (isDisconnected) return;
    isDisconnected = true;

    closeSocket();

    await Future.delayed(const Duration(seconds: 2));
    createConnection();
  }

  Future<void> createConnection() async {
    print('Create socket connection');
    gotHello = false;
    isDisconnected = false;
    try {
      const String overrideIp = String.fromEnvironment('WSSIP');
      final String socketUrl = overrideIp.isNotEmpty ? overrideIp : 'wss://v2.apparyllis.com';

      if (kIsWeb) {
        _WebSocket = WebSocketChannel.connect(Uri.parse(socketUrl));
      } else {
        _IOSocket = await io.WebSocket.connect(socketUrl,
            compression: const io.CompressionOptions(
                enabled: true, serverNoContextTakeover: true, clientNoContextTakeover: true, serverMaxWindowBits: 15, clientMaxWindowBits: 15));
        _IOSocket!.pingInterval = const Duration(seconds: 3);
      }

      if (kIsWeb) {
        _WebSocket!.stream.handleError((err) => disconnected());
        _WebSocket!.stream.listen(onData);

        sendAuthentication();

        _WebSocket!.sink.done.then((value) => disconnected());
      } else {
        _IOSocket!.handleError((err) => disconnected());
        _IOSocket!.listen(onData);

        sendAuthentication();

        _IOSocket!.done.then((value) => disconnected());
      }

      if (pingTimer != null && pingTimer!.isActive) {
        pingTimer!.cancel();
      }

      pingTimer = Timer.periodic(const Duration(seconds: 30), ping);
    } catch (e) {
      disconnected();
    }
  }

  void ping(Timer timer) {
    if (!isSocketLive()) {
      disconnected();
    }
    try {
      sendSocketData('ping');
    } catch (e) {
      disconnected();
    }
  }

  EChangeType operationToChangeType(String operation) {
    switch (operation) {
      case 'update':
        return EChangeType.Update;
      case 'insert':
        return EChangeType.Add;
      case 'delete':
        return EChangeType.Delete;
    }

    return EChangeType.Update;
  }

  void onData(event) {
    gotHello = true;
    API().debug().logFine('[SOCKET DATA RECEIVED] $event', bSave: false);
    if (event is String && event.isNotEmpty) {
      onReceivedData(event);
    }
  }

  Future<void> onReceivedData(event) async {
    if (event == 'pong') {
      return;
    }

    Map<String, dynamic> data = jsonDecode(event, reviver: customDecode);

    String? msg = data['msg'];

    if (msg == null) return;

    if (msg == 'update') {
      final bool initial = data['initial'] == true;

      if (initial) {
        // Clear the cache, we may have deleted things while on another phone
        API().cache().clearTypeCache(data['target']);
      }
      for (Map<String, dynamic> result in data['results']) {
        propogateChanges(data['target'], result['id'], jsonDataToDocumentData(data['target'], result['content'] as Map<String, dynamic>),
            operationToChangeType(result['operationType']), false);
      }
    } else {
      _OnMsgReceived.forEach((element) {
        if (element != null) {
          element(msg, data['data'] ?? '');
        }
      });
    }
  }
}

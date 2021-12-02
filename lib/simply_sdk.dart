library simply_sdk;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:simply_sdk/modules/auth.dart';
import 'package:simply_sdk/modules/cache.dart';
import 'package:simply_sdk/modules/config.dart';
import 'package:simply_sdk/modules/connection.dart';
import 'package:simply_sdk/modules/socket.dart';
import 'package:simply_sdk/modules/subscriptions.dart';

import 'modules/network.dart';

class APISettings {}

class API {
  static API _singleton = API();

  factory API() {
    return _singleton;
  }

  Future<void> initialize({APISettings? settings}) async {
    _auth = Auth();
    _cache = Cache();
    _connection = Connection();
    _socket = Socket();
    _network = Network();
    _documentSubscriptions = DocumentSubscriptions();
    _remoteConfig = RemoteConfig();
    await _cache.initialize("");
  }

  // Declare globals
  late Auth _auth;
  late Cache _cache;
  late Connection _connection;
  late Network _network;
  late Socket _socket;
  late DocumentSubscriptions _documentSubscriptions;
  late RemoteConfig _remoteConfig;

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Network network() => _network;
  Socket socket() => _socket;
  DocumentSubscriptions docSubscriptions() => _documentSubscriptions;
  RemoteConfig remoteConfig() => _remoteConfig;

  void reportError(e, StackTrace trace) {
    try {
      onErrorReported!(e, trace);
    } catch (e) {}
  }

  Function? onErrorReported;
}

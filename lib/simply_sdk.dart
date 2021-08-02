library simply_sdk;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:simply_sdk/auth.dart';
import 'package:simply_sdk/cache.dart';
import 'package:simply_sdk/connection.dart';
import 'package:simply_sdk/database.dart';
import 'package:simply_sdk/socket.dart';
import 'package:simply_sdk/subscriptions.dart';

class APISettings {}

class API {
  static final API _singleton = API._internal();

  factory API() {
    return _singleton;
  }

  API._internal();

  Future<void> initialize({APISettings settings}) async {
    _auth = Auth();
    _cache = Cache();
    _connection = Connection();
    _database = Database();
    _socket = Socket();
    _documentSubscriptions = DocumentSubscriptions();
    await _cache.initialize("");
  }

  // Declare globals
  Auth _auth;
  Cache _cache;
  Connection _connection;
  Database _database;
  Socket _socket;
  DocumentSubscriptions _documentSubscriptions;

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Database database() => _database;
  Socket socket() => _socket;
  DocumentSubscriptions docSubscriptions() => _documentSubscriptions;

  void reportError(e) {
    try {
      if (onErrorReported != null) onErrorReported(e);
    } catch (e) {}
  }

  void setGetHttpMetric(Function getFunction) {
    _getHttpMetricFunction = getFunction;
  }

  HttpMetric getHttpMetric(Uri url, HttpMethod method) {
    if (_getHttpMetricFunction != null) {
      return _getHttpMetricFunction(url, method);
    }
    return null;
  }

  Function onErrorReported;
  Function _getHttpMetricFunction;
}

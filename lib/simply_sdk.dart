library simply_sdk;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:simply_sdk/auth.dart';
import 'package:simply_sdk/cache.dart';
import 'package:simply_sdk/connection.dart';
import 'package:simply_sdk/database.dart';
import 'package:simply_sdk/socket.dart';

import 'package:http/http.dart' as http;

class APISettings {}

class API {
  static final API _singleton = API._internal();

  factory API() {
    return _singleton;
  }

  Dio httpClient;

  API._internal();

  Future<void> initialize({APISettings settings}) async {
    _auth = Auth();
    _cache = Cache();
    _connection = Connection();
    _database = Database();
    _socket = Socket();
    _socket.initialize();
    httpClient = Dio()
      ..options.baseUrl = connection().currentHost
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10000,
          // Ignore bad certificate
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );
    await _cache.initialize();
  }

  // Declare globals
  Auth _auth;
  Cache _cache;
  Connection _connection;
  Database _database;
  Socket _socket;

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Database database() => _database;
  Socket socket() => _socket;

  void reportError(e) {
    try {
      if (onErrorReported != null) onErrorReported(e);
    } catch (e) {}
  }

  Function onErrorReported;
}

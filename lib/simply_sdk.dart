library simply_sdk;

import 'package:simply_sdk/auth.dart';
import 'package:simply_sdk/cache.dart';
import 'package:simply_sdk/connection.dart';
import 'package:simply_sdk/database.dart';

class API {
  static final API _singleton = API._internal();

  factory API() {
    return _singleton;
  }

  API._internal() {
    _auth = Auth();
    _cache = Cache();
    _connection = Connection();
    _database = Database();
  }

  // Declare globals
  Auth _auth;
  Cache _cache;
  Connection _connection;
  Database _database;

  // Declare global getters
  Auth auth() => _auth;
  Connection connection() => _connection;
  Database database() => _database;
}

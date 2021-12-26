import 'dart:convert';
import 'dart:math';

import 'package:simply_sdk/simply_sdk.dart';

import 'user_test.dart' as user;
import 'pk_test.dart' as pk;
import 'cache_test.dart' as cache;
import 'store_test.dart' as store;
import 'socket_test.dart' as socket;

const String userId = "zdhE8LSYheP9dGzdwKzy8eoJrTu1";

String getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

void main() {
  API().connection().setCurrentHost("http://localhost:3000");
  API().auth().setLastAuthToken("testToken2", userId);
  user.runTests(userId);
  pk.runTests(userId);
  cache.runTests(userId);
  store.runTests(userId);
  socket.runTests(userId);
}

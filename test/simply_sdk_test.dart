import 'dart:convert';
import 'dart:math';

import 'package:simply_sdk/simply_sdk.dart';

import 'user_test.dart' as user;
import 'pk_test.dart' as pk;
import 'cache_test.dart' as cache;

const String userId = "rXH5xlieFOZ4ulqAlLv3YXLmn532";

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
}

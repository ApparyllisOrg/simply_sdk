import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:simply_sdk/simply_sdk.dart';

import 'user_test.dart' as user;
import 'pk_test.dart' as pk;
import 'cache_test.dart' as cache;
import 'store_test.dart' as store;
import 'socket_test.dart' as socket;
import 'front_history_test.dart' as fh;
import 'custom_fields_test.dart' as customfields;
import 'paginate_test.dart' as pagination;
import 'notes_test.dart' as notes;
import 'timers_test.dart' as timers;

const String userId = 'zdhE8LSYheP9dGzdwKzy8eoJrTu1';

String getRandString(int len) {
  final random = Random.secure();
  final values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

void main() {
  Logger.root.level = Level.ALL;
  API().connection().setCurrentHost('http://localhost:3000');
  //API().auth().setLastAuthToken("HvmRXTOBjp0nFbTxDx/t8ztim14BttGx2GQlS18cOAqLcf0569iDPEuEi16QxIjM", userId);
  socket.runTests(userId);
  user.runTests(userId);
  pk.runTests(userId);
  cache.runTests(userId);
  store.runTests(userId);
  fh.runTests(userId);
  customfields.runTests(userId);
  pagination.runTests(userId);
  notes.runTests(userId);
  timers.runTests(userId);
}

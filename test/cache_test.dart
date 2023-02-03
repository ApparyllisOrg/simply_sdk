import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/simply_sdk.dart';


void runTests(userId) {
  test('initialize cache', () async {
    API().cache().initialize(userId);
  });

  test('save cache', () async {
    API().cache().save();
  });

  test('add to cache', () async {
    API().cache().insertDocument('test', '0', {'field': 'value'});
  });

  test('save cache', () async {
    await API().cache().save();
  });

  test('reload cache', () async {
    API().cache().lastInitializeFor = '';
    await API().cache().initialize(userId);
  });
}

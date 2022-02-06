import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/simply_sdk.dart';

import 'simply_sdk_test.dart';

void runTests(userId) {
  test('initialize socket', () async {
    API().socket().initialize();
    await Future.delayed(Duration(seconds: 1));
    expect(API().socket().isSocketLive(), true);
    await Future.delayed(Duration(seconds: 10));
    expect(API().socket().isSocketLive(), true);
  });
}

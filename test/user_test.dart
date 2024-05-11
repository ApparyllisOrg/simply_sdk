import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/privates.dart';
import 'package:simply_sdk/api/users.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

import 'simply_sdk_test.dart';

void runTests(userId) {
  test('get user', () async {
    Document<UserData> user = await API().users().get(userId);
    expect(user.id, userId);
  });

  test('set username', () async {
    final String randomUsername = getRandString(64);
    await API().users().setUsername(randomUsername, userId);
    Document<UserData> user = await API().users().get(userId);
    expect(randomUsername, user.dataObject.username);
  });

  test('update user', () async {
    final String randomDesc = getRandString(64);
    API().users().update(
        userId,
        UserData()
          ..desc = randomDesc
          ..isAsystem = true);

    await Future.delayed(const Duration(seconds: 1));

    Document<UserData> user = await API().users().get(userId);
    expect(randomDesc, user.dataObject.desc);
    expect(true, user.dataObject.isAsystem);
  });

  test('get private', () async {
    Document<PrivateData> user = await API().privates().get(userId);
    expect(user.id, userId);
  });

  test('update private', () async {
    final String randomToken = getRandString(64);
    API().privates().update(
        userId,
        PrivateData()
          ..latestVersion = 0
          ..notificationToken = [randomToken]
          ..termsOfServiceAccepted = true);

    await Future.delayed(const Duration(seconds: 1));

    Document<PrivateData> user = await API().privates().get(userId);
    expect(randomToken, user.dataObject.notificationToken?[0]);
    expect(true, user.dataObject.termsOfServiceAccepted);
    expect(0, user.dataObject.latestVersion);
  });
}

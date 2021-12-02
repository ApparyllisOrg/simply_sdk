import 'dart:typed_data';

import 'package:simply_sdk/modules/http.dart';

import '../simply_sdk.dart';

class Storage {
  Future<bool> storeAvatar(String avatarUuid, Uint8List bytes) async {
    try {
      await SimplyHttpClient().post(
          Uri.parse(
              API().connection().getRequestUrl("v1/avatar/$avatarUuid", "")),
          body: {"buffer": bytes});

      return true;
    } catch (e) {}
    return false;
  }

  Future<void> deleteAvatar(String avatarUuid) async {
    try {
      await SimplyHttpClient().delete(Uri.parse(
          API().connection().getRequestUrl("v1/avatar/$avatarUuid", "")));
    } catch (e) {}
    return;
  }
}

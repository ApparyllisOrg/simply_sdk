import 'dart:typed_data';

import 'package:http/http.dart';

import '../simply_sdk.dart';

class Storage {
  Future<bool> storeAvatar(String avatarUuid, Uint8List bytes) async {
    try {
      await post(
          Uri.parse(
              API().connection().getRequestUrl("v1/avatar/$avatarUuid", "")),
          body: {"buffer": bytes});

      return true;
    } catch (e) {}
    return false;
  }

  Future<void> deleteAvatar(String avatarUuid) async {
    try {
      await delete(Uri.parse(
          API().connection().getRequestUrl("v1/avatar/$avatarUuid", "")));
    } catch (e) {}
    return;
  }
}

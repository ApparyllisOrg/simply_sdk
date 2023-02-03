import 'dart:convert';
import 'dart:typed_data';

import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class Storage {
  Future<RequestResponse> storeAvatar(String avatarUuid, Uint8List bytes) async {
    try {
      final result = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl('v1/avatar/$avatarUuid', '')), body: jsonEncode({'buffer': bytes})).catchError(((e) => generateFailedResponse(e)));

      return RequestResponse(result.statusCode == 200, result.body);
    } catch (e) {}
    return RequestResponse(false, 'Something went wrong');
  }

  Future<RequestResponse> deleteAvatar(String avatarUuid) async {
    try {
      final result = await SimplyHttpClient().delete(Uri.parse(API().connection().getRequestUrl('v1/avatar/$avatarUuid', ''))).catchError(((e) => generateFailedResponse(e)));
      return RequestResponse(result.statusCode == 200, result.body);
    } catch (e) {}
    return RequestResponse(false, 'Something went wrong');
  }
}

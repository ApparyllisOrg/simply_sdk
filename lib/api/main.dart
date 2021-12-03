import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import '../simply_sdk.dart';

void addSimpleDocument(String type, String path, DocumentData data,
    {String? overrideId}) {
  String generatedId = ObjectId(clientMode: true).toHexString();

  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(
      HttpRequestMethod.Post,
      "$path/${overrideId ?? generatedId}",
      DateTime.now().millisecondsSinceEpoch,
      payload: jsonPayload));

  API().cache().insertDocument(type, generatedId, jsonPayload);
}

void updateSimpleDocument(
    String type, String path, String documentId, DocumentData data) {
  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(HttpRequestMethod.Patch,
      "$path/$documentId", DateTime.now().millisecondsSinceEpoch,
      payload: jsonPayload));

  API().cache().updateDocument(type, documentId, jsonPayload);
}

void deleteSimpleDocument(String type, String path, String id) {
  API().network().request(new NetworkRequest(
        HttpRequestMethod.Delete,
        "$path/$id",
        DateTime.now().millisecondsSinceEpoch,
      ));
}

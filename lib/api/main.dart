import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import '../simply_sdk.dart';

Document<T> addSimpleDocument<T>(String type, String path, DocumentData data,
    {String? overrideId}) {
  String generatedId = ObjectId(clientMode: true).toHexString();

  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(
      HttpRequestMethod.Post,
      "$path/${overrideId ?? generatedId}",
      DateTime.now().millisecondsSinceEpoch,
      payload: jsonPayload));

  API().cache().insertDocument(type, generatedId, jsonPayload);

  return Document(true, overrideId ?? generatedId, data as T, type);
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

Future<List<Map<String, dynamic>>> getCollection<ObjectType>(
    String path, String id) async {
  var response = await SimplyHttpClient().patch(Uri.parse("$path/$id"));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return [];
}

void updateDocumentInList(List<Document> documents, Document updatedDocument) {
  int index =
      documents.indexWhere((element) => element.id == updatedDocument.id);
  if (index > 0) {
    documents[index] = updatedDocument;
  } else {
    documents.add(updatedDocument);
  }
}

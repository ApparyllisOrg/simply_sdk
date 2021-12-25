import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import '../simply_sdk.dart';

class DocumentResponse {
  late bool exists;
  late String id;
  late Map<String, dynamic> content;

  DocumentResponse.fromJson(Map<String, dynamic> json) {
    exists = json["exists"]!;
    id = json["id"]!;
    content = json["content"]!;
  }

  DocumentResponse.fromString(String jsonBody) {
    Map<String, dynamic> json = jsonDecode(jsonBody) as Map<String, dynamic>;
    exists = json["exists"]!;
    id = json["id"]!;
    content = json["content"]!;
  }
}

Document<T> addSimpleDocument<T>(String type, String path, DocumentData data, {String? overrideId}) {
  String generatedId = ObjectId(clientMode: true).toHexString();

  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(HttpRequestMethod.Post, "$path/${overrideId ?? generatedId}", DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));

  API().cache().insertDocument(type, generatedId, jsonPayload);

  return Document(true, overrideId ?? generatedId, data as T, type);
}

void updateSimpleDocument(String type, String path, String documentId, DocumentData data) {
  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(HttpRequestMethod.Patch, "$path/$documentId", DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));

  API().cache().updateDocument(type, documentId, jsonPayload);
}

void deleteSimpleDocument(String type, String path, String id) {
  API().network().request(new NetworkRequest(
        HttpRequestMethod.Delete,
        "$path/$id",
        DateTime.now().millisecondsSinceEpoch,
      ));
}

Future<List<Map<String, dynamic>>> getCollection<ObjectType>(String path, String id) async {
  var response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("$path/$id", "")));
  if (response.statusCode == 200) {
    List list = jsonDecode(response.body);
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
  return [];
}

void updateDocumentInList(List<Document> documents, Document updatedDocument, EChangeType changeType) {
  if (changeType == EChangeType.Delete) {
    documents.removeWhere((element) => element.id == updatedDocument.id);
  } else {
    int index = documents.indexWhere((element) => element.id == updatedDocument.id);
    if (index > 0) {
      documents[index] = updatedDocument;
    } else {
      documents.add(updatedDocument);
    }
  }
}

Future<Document<DataType>> getSimpleDocument<DataType>(String id, String url, String type, DataType Function(DocumentResponse data) createDoc, DataType Function() creatEmptyeDoc) async {
  var response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("$url/$id", "")));
  if (response.statusCode == 200) {
    return Document<DataType>(true, id, createDoc(DocumentResponse.fromString(response.body)), type);
  }
  return Document<DataType>(true, id, creatEmptyeDoc(), type);
}

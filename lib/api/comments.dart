import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
class CommentData implements DocumentData {
  Timestamp? time;
  String? text;
  String? documentId;
  String? collection;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("time", time, payload);
    insertData("text", text, payload);
    insertData("documentId", documentId, payload);
    insertData("collection", collection, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    time = readDataFromJson("time", json);
    text = readDataFromJson("text", json);
    documentId = readDataFromJson("documentId", json);
    collection = readDataFromJson("collection", json);
  }
}

class Comments extends Collection {
  @override
  String get type => "Comments";

  @override
  void add(DocumentData values) {
    addSimpleDocument(type, "v1/comment", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/comment", documentId);
  }

  @override
  Future<Document> get(String id) async {
    return Document(true, "", CommentData(), type);
  }

  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/comment", documentId, values);
  }
}

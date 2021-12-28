import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class CommentData implements DocumentData {
  int? time;
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

class Comments extends Collection<CommentData> {
  @override
  String get type => "Comments";

  @override
  Document<CommentData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/comment", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/comment", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<CommentData>> get(String id) async {
    return getSimpleDocument(id, "v1/comment/${API().auth().getUid()}", type, (data) => CommentData()..constructFromJson(data.content), () => CommentData());
  }

  @deprecated
  @override
  Future<List<Document<CommentData>>> getAll() async {
    throw UnimplementedError();
  }

  Future<List<Document<CommentData>>> getCommentsForDocument(String documentId, String type) async {
    var collection = await getCollection<CommentData>("v1/comments/$type/$documentId/", "");

    List<Document<CommentData>> comments = collection.map<Document<CommentData>>((e) => Document(e["exists"], e["id"], CommentData()..constructFromJson(e["content"]), type)).toList();

    return comments;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/comment", documentId, values);
  }
}

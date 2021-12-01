import 'package:simply_sdk/types/document.dart';

abstract class DocumentData {
  Map<String, dynamic> toJson();
  constructFromJson(Map<String, dynamic> json);
}

abstract class Collection {
  String collection;

  Future<Document> get(String id);
  Future<List<Document>> getAll();
  Future<void> add(DocumentData values);
  Future<void> update(String documentId, DocumentData values);
  Future<void> delete(String documentId);
}

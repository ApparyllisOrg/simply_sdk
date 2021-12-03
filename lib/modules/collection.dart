import 'package:simply_sdk/types/document.dart';

abstract class DocumentData {
  Map<String, dynamic> toJson();
  constructFromJson(Map<String, dynamic> json);
}

abstract class Collection {
  String type = "NONE";

  Future<Document<DocumentData>> get(String id);
  Future<List<Document<DocumentData>>> getAll();
  Document<DocumentData> add(DocumentData values);
  void update(String documentId, DocumentData values);
  void delete(String documentId);
}

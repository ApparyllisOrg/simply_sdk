import 'package:flutter/material.dart';
import 'package:simply_sdk/types/document.dart';

abstract class DocumentData {
  Map<String, dynamic> toJson();
  constructFromJson(Map<String, dynamic> json);
}

class EmptyDocumentData extends DocumentData {
  @override
  constructFromJson(Map<String, dynamic> json) {}

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}

enum EChangeType { Add, Update, Delete }

typedef DocumentChange = void Function(Document<dynamic>, EChangeType);

abstract class Collection<ObjectType> {
  String type = "NONE";

  List<DocumentChange?> boundChanges = [];

  Future<Document<DocumentData>> get(String id);
  Future<List<Document<DocumentData>>> getAll();
  Document<DocumentData> add(DocumentData values);
  void update(String documentId, DocumentData values);
  void delete(String documentId);

  void listenForChanges(DocumentChange bindFunc) {
    boundChanges.add(bindFunc);
  }

  void cancelListenForChanges(DocumentChange bindFunc) {
    boundChanges.remove(bindFunc);
  }

  void propogateChanges(Document<ObjectType> change, EChangeType changeType) {
    boundChanges.forEach((element) {
      if (element != null) element(change, changeType);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:simply_sdk/types/document.dart';

abstract class DocumentData {
  Map<String, dynamic> toJson();
  constructFromJson(Map<String, dynamic> json);
}

abstract class Collection {
  String type = "NONE";

  List<ValueChanged<Document<DocumentData>>?> boundChanges = [];

  Future<Document<DocumentData>> get(String id);
  Future<List<Document<DocumentData>>> getAll();
  Document<DocumentData> add(DocumentData values);
  void update(String documentId, DocumentData values);
  void delete(String documentId);

  void listenForChanges(ValueChanged<Document<DocumentData>> bindFunc) {
    boundChanges.add(bindFunc);
  }

  void cancelListenForChanges(ValueChanged<Document<DocumentData>> bindFunc) {
    boundChanges.remove(bindFunc);
  }

  void propogateChanges(Document<DocumentData> change) {
    boundChanges.forEach((element) {
      if (element != null) element(change);
    });
  }
}

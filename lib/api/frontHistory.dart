import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
class FrontHistoryData implements DocumentData {
  bool? custom;
  Timestamp? startTime;
  Timestamp? endTime;
  String? member;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("custom", custom, payload);
    insertData("startTime", startTime, payload);
    insertData("endTime", endTime, payload);
    insertData("member", member, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    custom = readDataFromJson("custom", json);
    startTime = readDataFromJson("startTime", json);
    endTime = readDataFromJson("endTime", json);
    member = readDataFromJson("member", json);
  }
}

class FrontHistory extends Collection {
  @override
  String get type => "FrontHistory";

  @override
  void add(DocumentData values) {
    addSimpleDocument(type, "v1/frontHistory", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/frontHistory", documentId);
  }

  @override
  Future<Document> get(String id) async {
    return Document(true, "", FrontHistoryData(), type);
  }

  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/frontHistory", documentId, values);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
class FronterData implements DocumentData {
  Timestamp? startTime;
  String? uuid;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("startTime", startTime, payload);
    insertData("uuid", uuid, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    startTime = readDataFromJson("startTime", json);
    uuid = readDataFromJson("uuid", json);
  }
}

class Fronters extends Collection {
  @override
  String get type => "Fronters";

  @override
  void add(DocumentData values) {
    addSimpleDocument(type, "v1/front", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/front", documentId);
  }

  @override
  Future<Document> get(String id) async {
    return Document(true, "", FronterData(), type);
  }

  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/front", documentId, values);
  }
}

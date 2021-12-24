import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/types/document.dart';

class FrontHistoryData implements DocumentData {
  bool? custom;
  int? startTime;
  int? endTime;
  String? member;
  bool? live;
  int? commentCount;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("custom", custom, payload);
    insertData("startTime", startTime, payload);
    insertData("endTime", endTime, payload);
    insertData("member", member, payload);
    insertData("live", live, payload);
    // Never send comment count

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    custom = readDataFromJson("custom", json);
    startTime = readDataFromJson("startTime", json);
    endTime = readDataFromJson("endTime", json);
    member = readDataFromJson("member", json);
    live = readDataFromJson("live", json);
    commentCount = readDataFromJson("commentCount", json);
  }
}

class FrontHistory extends Collection {
  @override
  String get type => "FrontHistory";

  @override
  Document<FrontHistoryData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/frontHistory", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/frontHistory", documentId);
  }

  @override
  Future<Document<FrontHistoryData>> get(String id) async {
    return Document(true, "", FrontHistoryData(), type);
  }

  @override
  Future<List<Document<FrontHistoryData>>> getAll() async {
    return [];
  }

  Future<List<Document<FrontHistoryData>>> getCurrentFronters() async {
     var response = await SimplyHttpClient().get(Uri.parse('v1/fronters'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/frontHistory", documentId, values);
  }
}

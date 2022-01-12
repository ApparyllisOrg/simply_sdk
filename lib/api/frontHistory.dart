import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class FrontHistoryData implements DocumentData {
  bool? custom;
  int? startTime;
  int? endTime;
  String? member;
  bool? live;
  int? commentCount;

  static FrontHistoryData copyFrom(FrontHistoryData other) {
    return FrontHistoryData()
      ..custom = other.custom
      ..startTime = other.startTime
      ..endTime = other.endTime
      ..member = other.member
      ..live = other.live
      ..commentCount = other.commentCount;
  }

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

class FrontHistory extends Collection<FrontHistoryData> {
  @override
  String get type => "FrontHistory";

  @override
  Document<FrontHistoryData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/frontHistory", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/frontHistory", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<FrontHistoryData>> get(String id) async {
    return getSimpleDocument(id, "v1/frontHistory/${API().auth().getUid()}", type, (data) => FrontHistoryData()..constructFromJson(data.content), () => FrontHistoryData());
  }

  @deprecated
  @override
  Future<List<Document<FrontHistoryData>>> getAll() async {
    throw UnimplementedError();
  }

  Future<List<Document<FrontHistoryData>>> getFrontHistoryInRange(int start, int end) async {
    var collection = await getCollection<FrontHistoryData>("v1/frontHistory/${API().auth().getUid()}", "", query: "startTime=$start&endTime=$end");

    List<Document<FrontHistoryData>> fronts = collection.map<Document<FrontHistoryData>>((e) => Document(e["exists"], e["id"], FrontHistoryData()..constructFromJson(e["content"]), type)).toList();

    return fronts;
  }

  Future<List<Document<FrontHistoryData>>> getCurrentFronters() async {
    var collection = await getCollection<FrontHistoryData>("v1/fronters", "");

    List<Document<FrontHistoryData>> fronts = collection.map<Document<FrontHistoryData>>((e) => Document(e["exists"], e["id"], FrontHistoryData()..constructFromJson(e["content"]), type)).toList();

    return fronts;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/frontHistory", documentId, values);
  }
}

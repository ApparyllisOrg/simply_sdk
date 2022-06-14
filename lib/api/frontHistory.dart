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
  String? customStatus;
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
    insertData("customStatus", customStatus, payload);

    // Only store comment count for cache reasons
    insertData("commentCount", commentCount, payload);

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
    customStatus = readDataFromJson("customStatus", json);
  }
}

class FrontHistory extends Collection<FrontHistoryData> {
  @override
  String get type => "FrontHistory";

  @override
  Document<FrontHistoryData> add(FrontHistoryData values) {
    values.commentCount = null;
    return addSimpleDocument(type, "v1/frontHistory", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(
        type, "v1/frontHistory", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<FrontHistoryData>> get(String id) async {
    return getSimpleDocument(
        id,
        "v1/frontHistory/${API().auth().getUid()}",
        type,
        (data) => FrontHistoryData()..constructFromJson(data.content),
        () => FrontHistoryData());
  }

  @deprecated
  @override
  Future<List<Document<FrontHistoryData>>> getAll() async {
    throw UnimplementedError();
  }

  Future<List<Document<FrontHistoryData>>> getFrontHistoryInRange(
      int start, int end) async {
    var collection = await getCollection<FrontHistoryData>(
        "v1/frontHistory/${API().auth().getUid()}", "", type,
        query: "startTime=$start&endTime=$end", skipCache: true);

    List<Document<FrontHistoryData>> fronts = collection.data
        .map<Document<FrontHistoryData>>((e) => Document(e["exists"], e["id"],
            FrontHistoryData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      List<Document<FrontHistoryData>> fhNotLive = API()
          .cache()
          .getDocumentsWhere<FrontHistoryData>(
              type,
              (doc) => (doc.dataObject.live ?? false) == false,
              (data) => FrontHistoryData()..constructFromJson(data));
      fhNotLive.forEach(
          (element) => API().cache().removeFromCache(type, element.id));
      API().cache().cacheListOfDocuments(fronts);
    }
    return fronts;
  }

  Future<List<Document<FrontHistoryData>>> getFrontHistoryInRangeOffline(
      int start, int end) async {
    return API().cache().getDocumentsWhere<FrontHistoryData>(type,
        (Document<FrontHistoryData> data) {
      int entryStart = data.dataObject.startTime ?? 0;
      int? entryEnd = data.dataObject.endTime;
      if (entryEnd == null) return false;

      if (entryStart > start || entryEnd > end)
        return true; // starts after start, ends after end
      if (entryStart < start || entryEnd > start)
        return true; //start before start, ends after start
      if (entryStart > start || entryEnd < end)
        return true; // start after start, ends before end
      if (entryStart < end || entryEnd > end)
        return true; //Starts before end, ends after end

      return false;
    },
        (Map<String, dynamic> data) =>
            FrontHistoryData()..constructFromJson(data));
  }

  Future<List<Document<FrontHistoryData>>> getCurrentFronters(
      {int? since, bool bForceOffline = false}) async {
    var collection = await getCollection<FrontHistoryData>(
        "v1/fronters", "", type,
        since: since, bForceOffline: bForceOffline);

    List<Document<FrontHistoryData>> fronts = collection.data
        .map<Document<FrontHistoryData>>((e) => Document(e["exists"], e["id"],
            FrontHistoryData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      List<Document<FrontHistoryData>> fhLive = API()
          .cache()
          .getDocumentsWhere<FrontHistoryData>(
              type,
              (doc) => doc.dataObject.live ?? false,
              (data) => FrontHistoryData()..constructFromJson(data));
      fhLive.forEach(
          (element) => API().cache().removeFromCache(type, element.id));
      API().cache().cacheListOfDocuments(fronts);
    }

    return fronts.where((element) => element.dataObject.live == true).toList();
  }

  @override
  void update(String documentId, FrontHistoryData values) {
    values.commentCount = null;
    updateSimpleDocument(type, "v1/frontHistory", documentId, values);
  }
}

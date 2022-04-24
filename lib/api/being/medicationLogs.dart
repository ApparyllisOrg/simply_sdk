import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class MedicationLogData implements DocumentData {
  String? ref;
  String? note;
  String? amount;
  int? time;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("ref", ref, payload);
    insertData("note", note, payload);
    insertData("amount", amount, payload);
    insertData("time", time, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    ref = readDataFromJson("ref", json);
    note = readDataFromJson("note", json);
    amount = readDataFromJson("amount", json);
    time = readDataFromJson("time", json);
  }
}

class MedicationLogs extends Collection<MedicationLogData> {
  @override
  String get type => "medicationLogs";

  @override
  Document<MedicationLogData> add(DocumentData values) {
    return addSimpleDocument(type, "being/v1/logs/medication", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "being/v1/logs/medication", documentId,
        originalDocument.dataObject);
  }

  @override
  Future<Document<MedicationLogData>> get(String id) async {
    return getSimpleDocument(
        id,
        "being/v1/logs/medication",
        type,
        (data) => MedicationLogData()..constructFromJson(data.content),
        () => MedicationLogData());
  }

  @override
  Future<List<Document<MedicationLogData>>> getAll(
      {String? uid, int? since}) async {
    var collection = await getCollection<MedicationLogData>(
        "being/v1/logs/medications", "", type,
        since: since);

    List<Document<MedicationLogData>> cfs = collection.data
        .map<Document<MedicationLogData>>((e) => Document(e["exists"], e["id"],
            MedicationLogData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(cfs);
      }
    }
    return cfs;
  }

  Future<List<Document<MedicationLogData>>> getLogEntriesInRange(
      int start, int end) async {
    var collection = await getCollection<MedicationLogData>(
        "being/v1/logs/medications", "", type,
        query: "startTime=$start&endTime=$end", skipCache: true);

    List<Document<MedicationLogData>> logs = collection.data
        .map<Document<MedicationLogData>>((e) => Document(e["exists"], e["id"],
            MedicationLogData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(logs);
    }
    return logs;
  }

  Future<List<Document<MedicationLogData>>> getLogEntriesInRangeOffline(
      int start, int end) async {
    return API().cache().getDocumentsWhere<MedicationLogData>(type,
        (Document<MedicationLogData> data) {
      int time = data.dataObject.time ?? 0;

      if (time >= start && time <= end) return true;

      return false;
    },
        (Map<String, dynamic> data) =>
            MedicationLogData()..constructFromJson(data));
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "being/v1/logs/medication", documentId, values);
  }
}

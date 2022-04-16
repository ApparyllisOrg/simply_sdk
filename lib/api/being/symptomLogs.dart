import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class SymptomLogData implements DocumentData {
  String? symptom;
  String? note;
  int? severity;
  int? time;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("symptom", symptom, payload);
    insertData("note", note, payload);
    insertData("severity", severity, payload);
    insertData("time", time, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    symptom = readDataFromJson("symptom", json);
    note = readDataFromJson("note", json);
    severity = readDataFromJson("severity", json);
    time = readDataFromJson("time", json);
  }
}

class SymptomLogs extends Collection<SymptomLogData> {
  @override
  String get type => "symptomLogs";

  @override
  Document<SymptomLogData> add(DocumentData values) {
    return addSimpleDocument(type, "being/v1/logs/symptom", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(
        type, "being/v1/logs/symptom", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<SymptomLogData>> get(String id) async {
    return getSimpleDocument(
        id,
        "being/v1/logs/symptom",
        type,
        (data) => SymptomLogData()..constructFromJson(data.content),
        () => SymptomLogData());
  }

  @override
  Future<List<Document<SymptomLogData>>> getAll(
      {String? uid, int? since}) async {
    var collection = await getCollection<SymptomLogData>(
        "being/v1/logs/symptom", "", type,
        since: since);

    List<Document<SymptomLogData>> cfs = collection.data
        .map<Document<SymptomLogData>>((e) => Document(e["exists"], e["id"],
            SymptomLogData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(cfs);
      }
    }
    return cfs;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "being/v1/logs/symptom", documentId, values);
  }
}

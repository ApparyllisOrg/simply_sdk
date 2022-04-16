import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class MedicationData implements DocumentData {
  String? name;
  String? desc;
  String? group;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("group", group, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    group = readDataFromJson("group", json);
  }
}

class Medication extends Collection<MedicationData> {
  @override
  String get type => "medication";

  @override
  Document<MedicationData> add(DocumentData values) {
    return addSimpleDocument(type, "being/v1/medication", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(
        type, "being/v1/medication", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<MedicationData>> get(String id) async {
    return getSimpleDocument(
        id,
        "being/v1/medication",
        type,
        (data) => MedicationData()..constructFromJson(data.content),
        () => MedicationData());
  }

  @override
  Future<List<Document<MedicationData>>> getAll(
      {String? uid, int? since}) async {
    var collection = await getCollection<MedicationData>(
        "being/v1/medications", "", type,
        since: since);

    List<Document<MedicationData>> cfs = collection.data
        .map<Document<MedicationData>>((e) => Document(e["exists"], e["id"],
            MedicationData()..constructFromJson(e["content"]), type))
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
    updateSimpleDocument(type, "being/v1/medication", documentId, values);
  }
}

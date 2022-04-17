import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class SymptomData implements DocumentData {
  String? name;
  String? desc;
  String? color;
  String? group;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("color", color, payload);
    insertData("group", group, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    color = readDataFromJson("color", json);
    group = readDataFromJson("group", json);
  }
}

class Symptoms extends Collection<SymptomData> {
  @override
  String get type => "symptoms";

  @override
  Document<SymptomData> add(DocumentData values) {
    return addSimpleDocument(type, "being/v1/symptom", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(
        type, "being/v1/symptom", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<SymptomData>> get(String id) async {
    return getSimpleDocument(
        id,
        "being/v1/symptom",
        type,
        (data) => SymptomData()..constructFromJson(data.content),
        () => SymptomData());
  }

  @override
  Future<List<Document<SymptomData>>> getAll({String? uid, int? since}) async {
    var collection = await getCollection<SymptomData>(
        "being/v1/symptom", "", type,
        since: since);

    List<Document<SymptomData>> cfs = collection.data
        .map<Document<SymptomData>>((e) => Document(e["exists"], e["id"],
            SymptomData()..constructFromJson(e["content"]), type))
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
    updateSimpleDocument(type, "being/v1/symptom", documentId, values);
  }
}

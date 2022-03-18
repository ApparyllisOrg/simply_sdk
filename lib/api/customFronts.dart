import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class CustomFrontData implements DocumentData {
  String? name;
  String? avatarUrl;
  String? avatarUuid;
  String? desc;
  String? color;
  bool? private;
  bool? preventTrusted;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("color", color, payload);
    insertData("avatarUuid", avatarUuid, payload);
    insertData("avatarUrl", avatarUrl, payload);
    insertData("private", private, payload);
    insertData("preventTrusted", preventTrusted, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    avatarUuid = readDataFromJson("avatarUuid", json);
    avatarUrl = readDataFromJson("avatarUrl", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    color = readDataFromJson("color", json);
  }
}

class CustomFronts extends Collection<CustomFrontData> {
  @override
  String get type => "CustomFronts";

  @override
  Document<CustomFrontData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/customFront", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/customFront", documentId, originalDocument.dataObject);
    API().store().getFronters().removeWhere((element) => element.dataObject.member == documentId);
  }

  @override
  Future<Document<CustomFrontData>> get(String id) async {
    return getSimpleDocument(id, "v1/customFront/${API().auth().getUid()}", type, (data) => CustomFrontData()..constructFromJson(data.content), () => CustomFrontData());
  }

  @override
  Future<List<Document<CustomFrontData>>> getAll({String? uid, int? since}) async {
    var collection = await getCollection<CustomFrontData>("v1/customFronts/${uid ?? API().auth().getUid()}", "", type, since: since);

    List<Document<CustomFrontData>> cfs = collection.data.map<Document<CustomFrontData>>((e) => Document(e["exists"], e["id"], CustomFrontData()..constructFromJson(e["content"]), type)).toList();
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
    updateSimpleDocument(type, "v1/customFront", documentId, values);
  }
}

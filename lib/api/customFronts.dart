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
  }
}

class CustomFronts extends Collection {
  List<Document<CustomFrontData>> _cachedCustomFronts = [];

  @override
  String get type => "CustomFronts";

  @override
  Document<CustomFrontData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/customFront", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/customFront", documentId);
  }

  @override
  Future<Document<CustomFrontData>> get(String id) async {
    return Document(true, "", CustomFrontData(), type);
  }

  @override
  Future<List<Document<CustomFrontData>>> getAll() async {
    var collection = await getCollection<CustomFrontData>(
        "v1/customFronts", API().auth().getUid() ?? "");

    List<Document<CustomFrontData>> customFronts =
        collection.map((e) => CustomFrontData()..constructFromJson(e))
            as List<Document<CustomFrontData>>;

    _cachedCustomFronts = customFronts;

    return customFronts;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/customFront", documentId, values);
  }

  List<Document<CustomFrontData>> getAllCachedCustomfronts() {
    return _cachedCustomFronts;
  }

  @override
  void propogateChanges(Document<DocumentData> change) {
    super.propogateChanges(change);
    updateDocumentInList(_cachedCustomFronts, change);
  }
}

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

import '../simply_sdk.dart';

class MemberData implements DocumentData {
  String? name;
  String? pronouns;
  String? avatarUrl;
  String? avatarUuid;
  String? desc;
  String? pkId;
  String? color;
  bool? private;
  bool? preventTrusted;
  bool? preventFrontNotifs;
  Map<String, String>? info;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("pronouns", pronouns, payload);
    insertData("pkId", pkId, payload);
    insertData("color", color, payload);
    insertData("avatarUuid", avatarUuid, payload);
    insertData("avatarUrl", avatarUrl, payload);
    insertData("private", private, payload);
    insertData("preventTrusted", preventTrusted, payload);
    insertData("preventFrontNotifs", preventFrontNotifs, payload);
    insertData("info", info, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    pronouns = readDataFromJson("pronouns", json);
    pkId = readDataFromJson("pkId", json);
    avatarUuid = readDataFromJson("avatarUuid", json);
    avatarUrl = readDataFromJson("avatarUrl", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    preventFrontNotifs = readDataFromJson("preventFrontNotifs", json);
    info = readDataFromJson("info", json);
  }
}

class Members extends Collection {
  List<Document<MemberData>> _cachedMembers = [];

  @override
  String get type => "Members";

  @override
  Document<MemberData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/member", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/member", documentId);
  }

  @override
  Future<Document<MemberData>> get(String id) async {
    return Document(true, "", MemberData(), type);
  }

  @override
  Future<List<Document<MemberData>>> getAll() async {
    var collection = await getCollection<MemberData>(
        "v1/members", API().auth().getUid() ?? "");

    List<Document<MemberData>> members =
        collection.map((e) => MemberData()..constructFromJson(e))
            as List<Document<MemberData>>;

    _cachedMembers = members;

    return members;
  }

  List<Document<MemberData>> getAllCachedMembers() {
    return _cachedMembers;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/member", documentId, values);
  }

  @override
  void propogateChanges(Document<DocumentData> change) {
    super.propogateChanges(change);
    updateDocumentInList(_cachedMembers, change);
  }
}

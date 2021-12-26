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

class Members extends Collection<MemberData> {
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
    return getSimpleDocument(id, "v1/member/${API().auth().getUid()}", type, (data) => MemberData()..constructFromJson(data.content), () => MemberData());
  }

  @override
  Future<List<Document<MemberData>>> getAll({String? uid}) async {
    var collection = await getCollection<MemberData>("v1/members/${(uid ?? API().auth().getUid()) ?? ""}", "");

    List<Document<MemberData>> members = collection.map<Document<MemberData>>((e) => Document(e["exists"], e["id"], MemberData()..constructFromJson(e["content"]), type)).toList();

    return members;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/member", documentId, values);
  }
}

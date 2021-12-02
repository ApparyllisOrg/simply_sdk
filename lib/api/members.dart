import 'package:firebase_performance/firebase_performance.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import '../simply_sdk.dart';

class MembersData implements DocumentData {
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
  @override
  String get type => "Members";

  @override
  void add(DocumentData values) {
    addSimpleDocument(type, "v1/member", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/member", documentId);
  }

  @override
  Future<Document> get(String id) async {
    return Document(true, "", MembersData(), type);
  }

  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/member", documentId, values);
  }
}

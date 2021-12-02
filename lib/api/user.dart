import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';

import '../simply_sdk.dart';

class UserFieldData implements DocumentData {
  String? name;
  int? order;
  bool? private;
  bool? preventTrusted;
  int? type;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    order = readDataFromJson("order", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    type = readDataFromJson("type", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("order", order, payload);
    insertData("private", private, payload);
    insertData("preventTrusted", preventTrusted, payload);
    insertData("type", type, payload);

    return payload;
  }
}

class UserData implements DocumentData {
  String? desc;
  bool? isAsystem;
  String? avatarUuid;
  String? color;
  Map<String, UserFieldData>? fields;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("desc", desc, payload);
    insertData("isAsystem", isAsystem, payload);
    insertData("avatarUuid", avatarUuid, payload);
    insertData("color", color, payload);
    insertData("fields", fields, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    desc = readDataFromJson("desc", json);
    isAsystem = readDataFromJson("isAsystem", json);
    avatarUuid = readDataFromJson("avatarUuid", json);
    color = readDataFromJson("color", json);

    Map<String, dynamic> _fields = readDataFromJson("fields", json);
    _fields.forEach((key, value) {
      _fields[key] = UserFieldData().constructFromJson(value);
    });

    fields = _fields as Map<String, UserFieldData>;
  }
}

class User extends Collection {
  @override
  String get type => "User";

  @deprecated
  @override
  void add(DocumentData values) {}

  @deprecated
  @override
  void delete(String documentId) {}

  @override
  Future<Document> get(String id) async {
    return Document(true, "", UserData(), type);
  }

  @deprecated
  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/user", documentId, values);
  }

  Future<void> setUsername(String newUsername, String userId) async {
    try {
      await SimplyHttpClient().patch(
          Uri.parse(
              API().connection().getRequestUrl("v1/user/username/$userId", "")),
          body: {"username": newUsername});
    } catch (e) {}
    return;
  }

  Future<void> deleteAccount() async
  {
    // Todo: Implement this
  }

  //Todo: Add generate user report
}

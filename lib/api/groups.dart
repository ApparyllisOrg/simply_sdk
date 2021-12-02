import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class GroupData implements DocumentData {
  String? parent;
  String? name;
  String? color;
  bool? private;
  bool? preventTrusted;
  String? desc;
  String? emoji;
  List<String>? members;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("parent", parent, payload);
    insertData("name", name, payload);
    insertData("color", color, payload);
    insertData("private", private, payload);
    insertData("desc", desc, payload);
    insertData("preventTrusted", preventTrusted, payload);
    insertData("emoji", emoji, payload);
    insertData("members", members, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    parent = readDataFromJson("parent", json);
    name = readDataFromJson("name", json);
    color = readDataFromJson("color", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    desc = readDataFromJson("desc", json);
    emoji = readDataFromJson("emoji", json);
    members = readDataFromJson("members", json);
  }
}

class Groups extends Collection {
  @override
  String get type => "Groups";

  @override
  void add(DocumentData values) {
    addSimpleDocument(type, "v1/group", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/group", documentId);
  }

  @override
  Future<Document> get(String id) async {
    return Document(true, "", GroupData(), type);
  }

  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/group", documentId, values);
  }
}

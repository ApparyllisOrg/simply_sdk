import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
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
  void constructFromJson(Map<String, dynamic> json) {
    parent = readDataFromJson("parent", json);
    name = readDataFromJson("name", json);
    color = readDataFromJson("color", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    desc = readDataFromJson("desc", json);
    emoji = readDataFromJson("emoji", json);
    members = readDataArrayFromJson<String>("members", json);
  }
}

class Groups extends Collection<GroupData> {
  @override
  String get type => "Groups";

  @override
  Document<GroupData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/group", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/group", documentId);
  }

  @override
  Future<Document<GroupData>> get(String id) async {
    return getSimpleDocument(id, "v1/group/${API().auth().getUid()}", type, (data) => GroupData()..constructFromJson(data.content), () => GroupData());
  }

  @override
  Future<List<Document<GroupData>>> getAll({String? uid}) async {
    var collection = await getCollection<GroupData>("v1/groups/${uid ?? API().auth().getUid()}", "");

    List<Document<GroupData>> groups = collection.map<Document<GroupData>>((e) => Document(e["exists"], e["id"], GroupData()..constructFromJson(e["content"]), type)).toList();

    return groups;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/group", documentId, values);
  }
}

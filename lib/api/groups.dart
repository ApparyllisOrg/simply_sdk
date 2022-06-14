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
    insertDataArray("members", members, payload);

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
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(
        type, "v1/group", documentId, originalDocument.dataObject);
    recursiveDeleteGroup(documentId);
  }

  @override
  Future<Document<GroupData>> get(String id) async {
    return getSimpleDocument(
        id,
        "v1/group/${API().auth().getUid()}",
        type,
        (data) => GroupData()..constructFromJson(data.content),
        () => GroupData());
  }

  @override
  Future<List<Document<GroupData>>> getAll(
      {String? uid, int? since, bool bForceOffline = false}) async {
    var collection = await getCollection<GroupData>(
        "v1/groups/${uid ?? API().auth().getUid()}", "", type,
        since: since, bForceOffline: bForceOffline);

    List<Document<GroupData>> groups = collection.data
        .map<Document<GroupData>>((e) => Document(e["exists"], e["id"],
            GroupData()..constructFromJson(e["content"]), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(groups);
      }
    }
    return groups;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/group", documentId, values);
  }

  void recursiveDeleteGroup(String groupId) {
    Iterable<Document<GroupData>> groups = List.from(API()
        .store()
        .getAllGroups()
        .where((element) => element.dataObject.parent == groupId));
    groups.forEach((element) {
      delete(element.id, element);
    });
  }
}

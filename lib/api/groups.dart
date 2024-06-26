import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class GroupData implements DocumentData, PrivacyBucketInterface {
  String? parent;
  String? name;
  String? color;
  String? desc;
  String? emoji;
  List<String>? members;
  bool? supportDescMarkdown;
  List<String>? buckets;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('parent', parent, payload);
    insertData('name', name, payload);
    insertData('color', color, payload);
    insertData('desc', desc, payload);
    insertData('emoji', emoji, payload);
    insertData('supportDescMarkdown', supportDescMarkdown, payload);
    insertData('buckets', buckets, payload);
    insertDataArray('members', members, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    parent = readDataFromJson('parent', json);
    name = readDataFromJson('name', json);
    color = readDataFromJson('color', json);
    desc = readDataFromJson('desc', json);
    emoji = readDataFromJson('emoji', json);
    supportDescMarkdown = readDataFromJson('supportDescMarkdown', json);
    members = readDataArrayFromJson<String>('members', json);
    buckets = readDataArrayFromJson('buckets', json);
  }

  @override
  List<String> getBuckets() {
    return buckets ?? [];
  }
  
  @override
  void setBuckets(List<String> inBuckets) {
    buckets = inBuckets;
  }
}

class Groups extends Collection<GroupData> {
  @override
  String get type => 'Groups';

  @override
  Document<GroupData> add(DocumentData values) {
    return addSimpleDocument(type, 'v2/group', values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/group', documentId, originalDocument.dataObject);
    recursiveDeleteGroup(documentId);
  }

  @override
  Future<Document<GroupData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/group/${API().auth().getUid()}', type, (data) => GroupData()..constructFromJson(data.content), () => GroupData());
  }

  @override
  Future<List<Document<GroupData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<GroupData>('v1/groups/${uid ?? API().auth().getUid()}', '', type, since: since, bForceOffline: bForceOffline);

    List<Document<GroupData>> groups =
        collection.data.map<Document<GroupData>>((e) => Document(e['exists'], e['id'], GroupData()..constructFromJson(e['content']), type)).toList();
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
    updateSimpleDocument(type, 'v1/group', documentId, values, propertiesToDelete: ['buckets']);
  }

  void recursiveDeleteGroup(String groupId) {
    Iterable<Document<GroupData>> groups = List.from(API().store().getAllGroups().where((element) => element.dataObject.parent == groupId));
    groups.forEach((element) {
      delete(element.id, element);
    });
  }

  Future<void> setGroupsForMember(String member, List<String> groups) async {
    final data = {"member": member, "groups": groups};
    final Map<String, dynamic> jsonPayload = data as Map<String, dynamic>;

    API().network().request(NetworkRequest(HttpRequestMethod.Patch, 'v1/group/members', DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));
  }
}

import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

import '../simply_sdk.dart';

class MemberData implements DocumentData, PrivacyBucketInterface {
  String? name;
  String? pronouns;
  String? avatarUrl;
  String? avatarUuid;
  String? desc;
  String? pkId;
  String? color;
  bool? preventFrontNotifs;
  bool? receiveMessageBoardNotifs;
  Map<String, String>? info;
  bool? supportDescMarkdown;
  bool? archived;
  String? archivedReason;
  FrameData? frame;
  List<String>? buckets;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('desc', desc, payload);
    insertData('pronouns', pronouns, payload);
    insertData('pkId', pkId, payload);
    insertData('color', color, payload);
    insertData('avatarUuid', avatarUuid, payload);
    insertData('avatarUrl', avatarUrl, payload);
    insertData('preventsFrontNotifs', preventFrontNotifs, payload);
    insertData('receiveMessageBoardNotifs', receiveMessageBoardNotifs, payload);
    insertData('info', info, payload);
    insertData('supportDescMarkdown', supportDescMarkdown, payload);
    insertData('archived', archived, payload);
    insertData('archivedReason', archivedReason, payload);

    insertDataArray('buckets', buckets, payload);

    insertData('frame', frame?.toJson(), payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    desc = readDataFromJson('desc', json);
    pronouns = readDataFromJson('pronouns', json);
    pkId = readDataFromJson('pkId', json);
    color = readDataFromJson('color', json);
    avatarUuid = readDataFromJson('avatarUuid', json);
    avatarUrl = readDataFromJson('avatarUrl', json);
    preventFrontNotifs = readDataFromJson('preventsFrontNotifs', json);
    receiveMessageBoardNotifs = readDataFromJson('receiveMessageBoardNotifs', json);
    supportDescMarkdown = readDataFromJson('supportDescMarkdown', json);
    archived = readDataFromJson('archived', json);
    archivedReason = readDataFromJson('archivedReason', json);

    buckets = readDataArrayFromJson('buckets', json);

    frame = FrameData()..constructFromOptionalJson(readDataFromJson('frame', json));

    if (json['info'] is Map<String, dynamic>) {
      Map<String, dynamic> map = json['info'] as Map<String, dynamic>;
      Map<String, String> infoFields = map.map<String, String>((key, value) {
        if (value != null) {
          return MapEntry(key, value as String);
        }
        return MapEntry(key, '');
      });

      info = infoFields;
    }
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

class Members extends Collection<MemberData> {
  @override
  String get type => 'Members';

  @override
  Document<MemberData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/member', values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/member', documentId, originalDocument.dataObject);
    API().store().getFronters().removeWhere((element) => element.dataObject.member == documentId);
  }

  @override
  Future<Document<MemberData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/member/${API().auth().getUid()}', type, (data) => MemberData()..constructFromJson(data.content), () => MemberData());
  }

  @override
  Future<List<Document<MemberData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<MemberData>("v1/members/${(uid ?? API().auth().getUid()) ?? ""}", '', type, since: since, bForceOffline: bForceOffline);

    final List<Document<MemberData>> members = collection.data
        .map<Document<MemberData>>((e) => Document(e['exists'], e['id'], MemberData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(members);
      }
    }
    return members;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/member', documentId, values, propertiesToDelete: ['buckets']);
  }

  void updateFields(String documentId, Map<String, String> values) {
    final Map<String, dynamic> data = {'info': values};

    API()
        .network()
        .request(NetworkRequest(HttpRequestMethod.Patch, 'v1/member/fields/$documentId', DateTime.now().millisecondsSinceEpoch, payload: data));

    API().cache().updateDocument(type, documentId, data);

    propogateChanges(type, documentId, MemberData()..info = values, EChangeType.Update, true);
  }
}

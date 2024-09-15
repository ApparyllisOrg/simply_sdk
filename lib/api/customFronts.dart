import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

class CustomFrontData implements DocumentData, PrivacyBucketInterface {
  String? name;
  String? avatarUrl;
  String? avatarUuid;
  String? desc;
  String? color;
  bool? supportDescMarkdown;
  FrameData? frame;
  List<String>? buckets;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('desc', desc, payload);
    insertData('color', color, payload);
    insertData('avatarUuid', avatarUuid, payload);
    insertData('avatarUrl', avatarUrl, payload);
    insertData('supportDescMarkdown', supportDescMarkdown, payload);
    insertData('frame', frame?.toJson(), payload);
    insertData('buckets', buckets, payload);
    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    desc = readDataFromJson('desc', json);
    avatarUuid = readDataFromJson('avatarUuid', json);
    avatarUrl = readDataFromJson('avatarUrl', json);
    color = readDataFromJson('color', json);
    supportDescMarkdown = readDataFromJson('supportDescMarkdown', json);
    frame = FrameData()..constructFromOptionalJson(readDataFromJson('frame', json));
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

class CustomFronts extends Collection<CustomFrontData> {
  @override
  String get type => 'FrontStatuses';

  @override
  Document<CustomFrontData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/customFront', values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/customFront', documentId, originalDocument.dataObject);
    API().store().getFronters().removeWhere((element) => element.dataObject.member == documentId);
  }

  @override
  Future<Document<CustomFrontData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/customFront/${API().auth().getUid()}', type, (data) => CustomFrontData()..constructFromJson(data.content), () => CustomFrontData());
  }

  @override
  Future<List<Document<CustomFrontData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<CustomFrontData>('v1/customFronts/${uid ?? API().auth().getUid()}', '', type, since: since, bForceOffline: bForceOffline);

    final List<Document<CustomFrontData>> cfs = collection.data
        .map<Document<CustomFrontData>>((e) => Document(e['exists'], e['id'], CustomFrontData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(cfs);
      }
    }
    return cfs;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/customFront', documentId, values, propertiesToDelete: ['buckets']);
  }
}

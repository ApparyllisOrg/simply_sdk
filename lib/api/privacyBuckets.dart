import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

class PrivacyBucketData implements DocumentData {
  String? name;
  String? desc;
  String? color;
  String? icon;
  String? rank;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('desc', desc, payload);
    insertData('color', color, payload);
    insertData('icon', icon, payload);
    insertData('rank', rank, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    desc = readDataFromJson('desc', json);
    color = readDataFromJson('color', json);
    icon = readDataFromJson('icon', json);
    rank = readDataFromJson('rank', json);
  }
}

class PrivacyBuckets extends Collection<PrivacyBucketData> {
  @override
  String get type => 'PrivacyBuckets';

  @override
  Document<PrivacyBucketData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/privacyBucket', values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/privacyBucket', documentId, originalDocument.dataObject);
    API().store().getFronters().removeWhere((element) => element.dataObject.member == documentId);
  }

  @override
  Future<Document<PrivacyBucketData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/privacyBucket/${API().auth().getUid()}', type, (data) => PrivacyBucketData()..constructFromJson(data.content), () => PrivacyBucketData());
  }

  @override
  Future<List<Document<PrivacyBucketData>>> getAll({int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<PrivacyBucketData>('v1/privacyBuckets', '', type, since: since, bForceOffline: bForceOffline);

    final List<Document<PrivacyBucketData>> buckets = collection.data
        .map<Document<PrivacyBucketData>>((e) => Document(e['exists'], e['id'], PrivacyBucketData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(buckets);
    }
    return buckets;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/privacyBucket', documentId, values);
  }

  void updateOrders(Map<String, String> newOrders)
  {
    final Map<String, dynamic> jsonPayload = {};
    final List<Map<String, String>> orders = [];

    newOrders.forEach((key, value) => orders.add({
      'id': key,
      'rank': value
    }));

    jsonPayload['buckets'] = orders;

    API().network().request(NetworkRequest(HttpRequestMethod.Patch, 'v1/privacyBucket/order', DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));
  }
}

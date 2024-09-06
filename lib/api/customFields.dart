import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

class CustomFieldData implements DocumentData, PrivacyBucketInterface {
  String? name;
  String? order;
  int? type;
  bool? supportMarkdown;
  List<String>? buckets;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('order', order, payload);
    insertData('type', type, payload);
    insertData('supportMarkdown', supportMarkdown, payload);
    insertDataArray('buckets', buckets, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    order = readDataFromJson('order', json);
    type = readDataFromJson('type', json);
    supportMarkdown = readDataFromJson('supportMarkdown', json);
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

class CustomFields extends Collection<CustomFieldData> {
  @override
  String get type => 'CustomFields';

  @override
  Document<CustomFieldData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/customField', values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/customField', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<CustomFieldData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/customField/${API().auth().getUid()}', type, (data) => CustomFieldData()..constructFromJson(data.content), () => CustomFieldData());
  }

  @override
  Future<List<Document<CustomFieldData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<CustomFieldData>('v1/customFields/${uid ?? API().auth().getUid()}', '', type, since: since, bForceOffline: bForceOffline);

    final List<Document<CustomFieldData>> customFields = collection.data
        .map<Document<CustomFieldData>>((e) => Document(e['exists'], e['id'], CustomFieldData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(customFields);
      }
    }
    return customFields;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/customField', documentId, values, propertiesToDelete: ['buckets']);
  }

  void setOrder(Map<String, String> newOrders) {
    final Map<String, dynamic> jsonPayload = {};
    final List<Map<String, String>> orders = [];

    newOrders.forEach((key, value) => orders.add({'id': key, 'order': value}));

    jsonPayload['fields'] = orders;

    API()
        .network()
        .request(NetworkRequest(HttpRequestMethod.Patch, 'v1/customField/order', DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));
  }
}

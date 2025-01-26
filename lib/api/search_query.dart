import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

class SearchQueryDataEntry implements DocumentData {
  String? type;
  Map<String, String>? payload;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonPayload = {};

    insertData('type', type, jsonPayload);
    insertDataMap('payload', payload, jsonPayload);

    return jsonPayload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    type = readDataFromJson('type', json);
    payload = readDataFromJson('payload', json);
    type = readDataFromJson('type', json);
  }
}

class SearchQueryData implements DocumentData {
  String? name;
  String? op;
  String? order;
  List<SearchQueryDataEntry>? entries;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('op', op, payload);
    insertData('order', order, payload);
    insertDataArray('order', entries, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    op = readDataFromJson('op', json);
    order = readDataFromJson('order', json);
    entries = readDataArrayFromJson('entries', json);
  }
}

class SearchQueries extends Collection<SearchQueryData> {
  @override
  String get type => 'SearchQueries';

  @override
  Document<SearchQueryData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/searchQuery', values);
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/searchQuery', documentId, values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/searchQuery', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<SearchQueryData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/searchQuery/${API().auth().getUid()}', type, (data) => SearchQueryData()..constructFromJson(data.content), () => SearchQueryData());
  }

  @override
  Future<List<Document<SearchQueryData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection = await getCollection<SearchQueryData>('v1/searchQueries/${uid ?? API().auth().getUid()}', '', type,
        since: since, bForceOffline: bForceOffline);

    final List<Document<SearchQueryData>> searchQueries = collection.data
        .map<Document<SearchQueryData>>((e) => Document(e['exists'], e['id'], SearchQueryData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(searchQueries);
      }
    }
    return searchQueries;
  }
}

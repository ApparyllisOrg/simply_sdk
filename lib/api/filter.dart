import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

class FilterDataEntry implements DocumentData {
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
  }
}

class FilterData implements DocumentData {
  String? name;
  String? desc;
  String? color;
  String? icon;
  String? op;
  String? order;
  List<FilterDataEntry>? entries;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('desc', desc, payload);
    insertData('color', color, payload);
    insertData('icon', icon, payload);
    insertData('op', op, payload);
    insertData('order', order, payload);
    insertDataArray('entries', entries, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    desc = readDataFromJson('desc', json);
    color = readDataFromJson('color', json);
    icon = readDataFromJson('icon', json);
    op = readDataFromJson('op', json);
    order = readDataFromJson('order', json);
    entries = readDataArrayFromJson('entries', json);
  }
}

class Filters extends Collection<FilterData> {
  @override
  String get type => 'Filters';

  @override
  Document<FilterData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/filter', values);
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/filter', documentId, values, propertiesToDelete: ['buckets']);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/filter', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<FilterData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/filter/${API().auth().getUid()}', type, (data) => FilterData()..constructFromJson(data.content), () => FilterData());
  }

  @override
  Future<List<Document<FilterData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection =
        await getCollection<FilterData>('v1/filters/${uid ?? API().auth().getUid()}', '', type, since: since, bForceOffline: bForceOffline);

    final List<Document<FilterData>> filterQueries = collection.data
        .map<Document<FilterData>>((e) => Document(e['exists'], e['id'], FilterData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(filterQueries);
      }
    }
    return filterQueries;
  }
}

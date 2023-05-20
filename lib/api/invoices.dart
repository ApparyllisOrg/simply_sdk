import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

import '../simply_sdk.dart';

class InvoiceData implements DocumentData {
  String? currency;
  String? url;
  int? time;
  int? price;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('currency', currency, payload);
    insertData('url', url, payload);
    insertData('time', time, payload);
    insertData('price', price, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    currency = readDataFromJson('currency', json);
    url = readDataFromJson('url', json);
    time = readDataFromJson('time', json);
    price = readDataFromJson('price', json);
  }
}

class Invoices extends Collection<InvoiceData> {
  @override
  String get type => 'Invoices';

  @override
  Document<InvoiceData> add(DocumentData values) {
    throw UnimplementedError();
  }

  @override
  void delete(String documentId, Document originalDocument) {
    throw UnimplementedError();
  }

  @override
  Future<Document<InvoiceData>> get(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Document<InvoiceData>>> getAll(
      {String? uid, int? since, bool bForceOffline = false}) async {
    final collection = await getCollection<InvoiceData>(
        "v1/subscription/invoices", '', type,
        since: since, bForceOffline: bForceOffline);

    List<Document<InvoiceData>> invoices = collection.data
        .map<Document<InvoiceData>>((e) => Document(e['exists'], e['id'],
            InvoiceData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(invoices);
      }
    }
    return invoices;
  }

  @override
  void update(String documentId, DocumentData values) {
    throw UnimplementedError();
  }
}

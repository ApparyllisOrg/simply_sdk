import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';

import '../simply_sdk.dart';

class AuditEntry implements DocumentData {
  String? property;
  String? oldValue;
  String? newValue;
  bool? customName;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    property = readDataFromJson('p', json);
    oldValue = readDataFromJson('o', json);
    newValue = readDataFromJson('n', json);
    customName = readDataFromJson('cn', json);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};
    return payload;
  }
}

class AuditData implements DocumentData {
  int? timestamp;
  int? exp;
  List<AuditEntry>? changes;
  String? name;
  String? coll;
  String? id;
  String? action;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};
    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    action = readDataFromJson('a', json);
    name = readDataFromJson('name', json);
    coll = readDataFromJson('coll', json);
    id = readDataFromJson('id', json);
    timestamp = readDataFromJson('t', json);
    exp = readDataFromJson('exp', json);

    changes = [];

    final List<dynamic>? _changes = readDataFromJson('changes', json);
    if (_changes != null) {
      _changes.forEach((value) {
        changes!.add(AuditEntry()..constructFromJson(value as Map<String, dynamic>));
      });
    }
  }
}

// Empty class with no implementation, all fetching is to be done through the Paginate widget
class Audit extends Collection<AuditData> {
  @override
  String get type => 'Audit';

  @override
  Document<AuditData> add(DocumentData values) {
    throw UnimplementedError();
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/audit', documentId, originalDocument.dataObject);
  }

  void deleteExpired(Function onDone) {
    API().network().request(NetworkRequest(HttpRequestMethod.Delete, 'v1/audits', DateTime.now().millisecondsSinceEpoch, onDone: onDone));
  }

  @override
  Future<Document<AuditData>> get(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Document<AuditData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    throw UnimplementedError();
  }

  @override
  void update(String documentId, DocumentData values) {
    throw UnimplementedError();
  }
}

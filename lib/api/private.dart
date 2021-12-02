import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class PrivateData implements DocumentData {
  List<String>? notificationTokens;
  int? latestVersion;
  String? location;
  bool? termsOfServicesAccepted;
  int? whatsNew;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("notificationTokens", notificationTokens, payload);
    insertData("latestVersion", latestVersion, payload);
    insertData("location", location, payload);
    insertData("termsOfServicesAccepted", termsOfServicesAccepted, payload);
    insertData("whatsNew", whatsNew, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    notificationTokens = readDataFromJson("notificationTokens", json);
    latestVersion = readDataFromJson("latestVersion", json);
    location = readDataFromJson("location", json);
    termsOfServicesAccepted = readDataFromJson("termsOfServicesAccepted", json);
    whatsNew = readDataFromJson("whatsNew", json);
  }
}

class Private extends Collection {
  @override
  String get type => "Private";

  @deprecated
  @override
  void add(DocumentData values) {}

  @deprecated
  @override
  void delete(String documentId) {}

  @override
  Future<Document> get(String id) async {
    return Document(true, "", PrivateData(), type);
  }

  @deprecated
  @override
  Future<List<Document>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/private", documentId, values);
  }
}

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class PrivateData implements DocumentData {
  List<String>? notificationToken;
  int? latestVersion;
  String? location;
  bool? termsOfServicesAccepted;
  int? whatsNew;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("notificationToken", notificationToken, payload);
    insertData("latestVersion", latestVersion, payload);
    insertData("location", location, payload);
    insertData("termsOfServicesAccepted", termsOfServicesAccepted, payload);
    insertData("whatsNew", whatsNew, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    notificationToken = readDataFromJson("notificationToken", json);
    latestVersion = readDataFromJson("latestVersion", json);
    location = readDataFromJson("location", json);
    termsOfServicesAccepted = readDataFromJson("termsOfServicesAccepted", json);
    whatsNew = readDataFromJson("whatsNew", json);
  }
}

class Privates extends Collection {
  @override
  String get type => "Privates";

  @deprecated
  @override
  Document<PrivateData> add(DocumentData values) {
    throw UnimplementedError();
  }

  @deprecated
  @override
  void delete(String documentId) {
    throw UnimplementedError();
  }

  @override
  Future<Document<PrivateData>> get(String id) async {
    return Document(true, "", PrivateData(), type);
  }

  @deprecated
  @override
  Future<List<Document<PrivateData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/private", documentId, values);
  }
}

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class PrivateData implements DocumentData {
  List<String>? notificationToken;
  int? latestVersion;
  String? location;
  bool? termsOfServiceAccepted;
  int? whatsNew;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("notificationToken", notificationToken, payload);
    insertData("latestVersion", latestVersion, payload);
    insertData("location", location, payload);
    insertData("termsOfServiceAccepted", termsOfServiceAccepted, payload);
    insertData("whatsNew", whatsNew, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    notificationToken = readDataArrayFromJson<String>("notificationToken", json);
    latestVersion = readDataFromJson("latestVersion", json);
    location = readDataFromJson("location", json);
    termsOfServiceAccepted = readDataFromJson("termsOfServiceAccepted", json);
    whatsNew = readDataFromJson("whatsNew", json);
  }
}

class Privates extends Collection<PrivateData> {
  @override
  String get type => "Privates";

  @deprecated
  @override
  Document<PrivateData> add(DocumentData values) {
    throw UnimplementedError();
  }

  @deprecated
  @override
  void delete(String documentId, Document originalDocument) {
    throw UnimplementedError();
  }

  @override
  Future<Document<PrivateData>> get(String id) async {
    return getSimpleDocument(id, "v1/user/private", "private", (data) => PrivateData()..constructFromJson(data.content), () => PrivateData());
  }

  @deprecated
  @override
  Future<List<Document<PrivateData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, PrivateData values) {
    updateSimpleDocument(type, "v1/user/private", documentId, values);
  }
}

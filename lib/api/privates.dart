import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

import '../modules/http.dart';
import '../modules/network.dart';

class Notification {
  Notification({required this.timestamp, required this.title, required this.message});

  int timestamp;
  String title;
  String message;
}

class PrivateData implements DocumentData {
  List<String>? notificationToken;
  int? latestVersion;
  String? location;
  bool? termsOfServiceAccepted;
  int? whatsNew;
  int? generationsLeft;
  List<Notification>? notifications;
  List<String>? categories;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('notificationToken', notificationToken, payload);
    insertData('latestVersion', latestVersion, payload);
    insertData('location', location, payload);
    insertData('termsOfServiceAccepted', termsOfServiceAccepted, payload);
    insertData('whatsNew', whatsNew, payload);
    insertDataArray('categories', categories, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    notificationToken = readDataArrayFromJson<String>('notificationToken', json);
    latestVersion = readDataFromJson('latestVersion', json);
    location = readDataFromJson('location', json);
    termsOfServiceAccepted = readDataFromJson('termsOfServiceAccepted', json);
    whatsNew = readDataFromJson('whatsNew', json);
    generationsLeft = readDataFromJson('generationsLeft', json);

    final notifs = readDataArrayFromJson<dynamic>('notificationHistory', json);
    notifications = (notifs ?? []).map((e) => Notification(timestamp: e['timestamp'], title: e['title'], message: e['message'])).toList();

    categories = readDataArrayFromJson<String>('categories', json);
  }
}

class Privates extends Collection<PrivateData> {
  @override
  String get type => 'Privates';

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
    return getSimpleDocument(id, 'v1/user/private', 'private', (data) => PrivateData()..constructFromJson(data.content), () => PrivateData());
  }

  @deprecated
  @override
  Future<List<Document<PrivateData>>> getAll() async {
    return [];
  }

  @override
  Future<void> update(String documentId, PrivateData values) async {
    Map<String, dynamic> jsonPayload = values.toJson();

    API().cache().updateDocument(type, documentId, jsonPayload);

    propogateChanges(type, documentId, values, EChangeType.Update, true);

    final response = await SimplyHttpClient()
        .patch(Uri.parse(API().connection().getRequestUrl('v1/user/private/${API().auth().getUid()}', '')), body: jsonEncode(jsonPayload))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return;
    }

    API().network().request(new NetworkRequest(
        HttpRequestMethod.Patch, 'v1/user/private/${API().auth().getUid()}', DateTime.now().millisecondsSinceEpoch,
        payload: jsonPayload));
  }
}

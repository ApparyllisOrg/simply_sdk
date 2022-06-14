import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/automatedTimers.dart';
import 'package:simply_sdk/api/comments.dart';
import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/api/notes.dart';
import 'package:simply_sdk/api/polls.dart';
import 'package:simply_sdk/api/repeatedTimers.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import '../simply_sdk.dart';

class DocumentResponse {
  late bool exists;
  late String id;
  late Map<String, dynamic> content;

  DocumentResponse();

  DocumentResponse.fromJson(Map<String, dynamic> json) {
    exists = json["exists"]!;
    id = json["id"]!;
    content = json["content"]!;
  }

  DocumentResponse.fromString(String jsonBody) {
    Map<String, dynamic> json = jsonDecode(jsonBody) as Map<String, dynamic>;
    exists = json["exists"]!;
    id = json["id"]!;
    content = json["content"]!;
  }
}

class CollectionResponse<Type> {
  bool useOffline = true;
  List<Map<String, dynamic>> data = [];

  CollectionResponse();
}

DocumentData jsonDataToDocumentData(String type, Map<String, dynamic> data) {
  switch (type) {
    case "Members":
    case "members":
      return MemberData()..constructFromJson(data);
    case "CustomFronts":
    case "frontStatuses":
      return CustomFrontData()..constructFromJson(data);
    case "Groups":
    case "groups":
      return GroupData()..constructFromJson(data);
    case "Notes":
    case "notes":
      return NoteData()..constructFromJson(data);
    case "Polls":
    case "polls":
      return PollData()..constructFromJson(data);
    case "RepeatedReminders":
    case "repeatedReminders":
      return RepeatedTimerData()..constructFromJson(data);
    case "AutomatedReminders":
    case "automatedReminders":
      return AutomatedTimerData()..constructFromJson(data);
    case "FrontHistory":
    case "frontHistory":
      return FrontHistoryData()..constructFromJson(data);
    case "Comments":
    case "comments":
      return CommentData()..constructFromJson(data);
  }

  return EmptyDocumentData();
}

void propogateChanges(
    String type, String id, dynamic data, EChangeType changeType) {
  switch (type) {
    case "Members":
    case "members":
      API()
          .members()
          .propogateChanges(Document(true, id, data, "Members"), changeType);
      break;
    case "CustomFronts":
    case "frontStatuses":
      API().customFronts().propogateChanges(
          Document(true, id, data, "CustomFronts"), changeType);
      break;
    case "Groups":
    case "groups":
      API()
          .groups()
          .propogateChanges(Document(true, id, data, "Groups"), changeType);
      break;
    case "Notes":
    case "notes":
      API()
          .notes()
          .propogateChanges(Document(true, id, data, "Notes"), changeType);
      break;
    case "Polls":
    case "polls":
      API()
          .polls()
          .propogateChanges(Document(true, id, data, "Polls"), changeType);
      break;
    case "RepeatedReminders":
    case "repeatedReminders":
      API().repeatedTimers().propogateChanges(
          Document(true, id, data, "RepeatedReminders"), changeType);
      break;
    case "AutomatedReminders":
    case "automatedReminders":
      API().automatedTimers().propogateChanges(
          Document(true, id, data, "AutomatedReminders"), changeType);
      break;
    case "FrontHistory":
    case "frontHistory":
      API().frontHistory().propogateChanges(
          Document(true, id, data, "FrontHistory"), changeType);
      break;
    case "Comments":
    case "comments":
      API()
          .comments()
          .propogateChanges(Document(true, id, data, "Comments"), changeType);
      break;
  }
}

Document<T> addSimpleDocument<T>(String type, String path, DocumentData data,
    {String? overrideId}) {
  String generatedId = ObjectId(clientMode: true).toHexString();

  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(
      HttpRequestMethod.Post,
      "$path/${overrideId ?? generatedId}",
      DateTime.now().millisecondsSinceEpoch,
      payload: jsonPayload));

  API().cache().insertDocument(type, generatedId, jsonPayload);

  propogateChanges(type, generatedId, data, EChangeType.Add);

  return Document(true, overrideId ?? generatedId, data as T, type);
}

void updateSimpleDocument(
    String type, String path, String documentId, DocumentData data) {
  Map<String, dynamic> jsonPayload = data.toJson();

  API().network().request(new NetworkRequest(HttpRequestMethod.Patch,
      "$path/$documentId", DateTime.now().millisecondsSinceEpoch,
      payload: jsonPayload));

  API().cache().updateDocument(type, documentId, jsonPayload);

  propogateChanges(type, documentId, data, EChangeType.Update);
}

void deleteSimpleDocument(
    String type, String path, String id, DocumentData data) {
  API().network().request(new NetworkRequest(
        HttpRequestMethod.Delete,
        "$path/$id",
        DateTime.now().millisecondsSinceEpoch,
      ));

  API().cache().removeDocument(type, id);

  propogateChanges(type, id, data, EChangeType.Delete);
}

Future<CollectionResponse<ObjectType>> getCollection<ObjectType>(
    String path, String id, String type,
    {String? query, skipCache: false, int? since}) async {
  var useQuery =
      (query ?? "") + (since != null ? "&since=${since.toString()}" : "");
  var response = await SimplyHttpClient()
      .get(Uri.parse(API().connection().getRequestUrl("$path/$id", useQuery)))
      .catchError(((e) => generateFailedResponse(e)));
  if (response.statusCode == 200) {
    CollectionResponse<ObjectType> res = CollectionResponse<ObjectType>();
    res.useOffline = false;
    res.data = convertServerResponseToList(response);
    return res;
  } else {
    API().debug().logFine("Failed get Collection result => ");
    API()
        .debug()
        .logFine(API().connection().getRequestUrl("$path/$id", useQuery));
    API().debug().logFine(response.body);
  }

  if (!skipCache) {
    CollectionResponse<ObjectType> res = CollectionResponse<ObjectType>();
    res.useOffline = true;
    List<Map<String, dynamic>> data = [];
    Map<String, dynamic> cachedData = API().cache().getTypeCache(type);
    cachedData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        data.add({"exists": true, "id": key, "content": value});
      }
    });
    res.data = data;
    return res;
  }

  CollectionResponse<ObjectType> res = CollectionResponse<ObjectType>();
  res.useOffline = true;
  res.data = [];
  return res;
}

void updateDocumentInList<ObjectType>(List<Document> documents,
    Document<ObjectType> updatedDocument, EChangeType changeType) {
  if (changeType == EChangeType.Delete) {
    documents.removeWhere((element) => element.id == updatedDocument.id);
  } else {
    int index =
        documents.indexWhere((element) => element.id == updatedDocument.id);
    if (index >= 0) {
      documents[index].data.addAll(updatedDocument.data);
      documents[index].dataObject.constructFromJson(documents[index].data);
    } else {
      documents.add(updatedDocument);
    }
  }
}

Future<Document<DataType>> getSimpleDocument<DataType>(
    String id,
    String url,
    String type,
    DataType Function(DocumentResponse data) createDoc,
    DataType Function() creatEmptyeDoc,
    {bool bForceOffline = false}) async {
  var response = bForceOffline
      ? Response("", 503)
      : await SimplyHttpClient()
          .get(Uri.parse(API().connection().getRequestUrl("$url/$id", "")))
          .catchError(((e) => generateFailedResponse(e)));
  if (response.statusCode == 200) {
    DataType data = createDoc(DocumentResponse.fromString(response.body));

    Document<DataType> doc = Document<DataType>(true, id, data, type);

    API()
        .cache()
        .updateToCache(type, id, (doc.dataObject as DocumentData).toJson());

    return doc;
  }

  Map<String, dynamic>? maybeData = API().cache().getDocument(type, id);

  if (maybeData != null) {
    DocumentResponse fakeResponse = DocumentResponse();
    fakeResponse.id = id;
    fakeResponse.content = maybeData;
    fakeResponse.exists = true;
    return Document<DataType>(true, id, createDoc(fakeResponse), type);
  }

  return Document<DataType>(true, id, creatEmptyeDoc(), type);
}

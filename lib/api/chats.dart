import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/abstractModel.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class ChannelData implements DocumentData {
  String? name;
  String? color;
  String? desc;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    color = readDataFromJson('color', json);
    desc = readDataFromJson('desc', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('color', color, payload);
    insertData('desc', desc, payload);

    return payload;
  }
}

class ChatMessageData implements DocumentData {
  String? message;
  String? channel;
  String? writer;
  int? writtenAt;
  String? replyTo;
  int? updatedAt;

  @override
  constructFromJson(Map<String, dynamic> json) {
    message = readDataFromJson('message', json);
    channel = readDataFromJson('channel', json);
    writer = readDataFromJson('writer', json);
    writtenAt = readDataFromJson('writtenAt', json);
    replyTo = readDataFromJson('replyTo', json);
    updatedAt = readDataFromJson('updatedAt', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('message', message, payload);
    insertData('channel', channel, payload);
    insertData('writer', writer, payload);
    insertData('writtenAt', writtenAt, payload);
    insertData('replyTo', replyTo, payload);
    insertData('updatedAt', updatedAt, payload);

    return payload;
  }
}

class ChatMessageDataId extends ChatMessageData {
  ChatMessageDataId(ChatMessageData data, String inId) {
    message = data.message;
    channel = data.channel;
    writer = data.writer;
    writtenAt = data.writtenAt;
    replyTo = data.replyTo;
    updatedAt = data.updatedAt;
    id = inId;
  }
  String? id;

  @override
  constructFromJson(Map<String, dynamic> json) {
    message = readDataFromJson('message', json);
    channel = readDataFromJson('channel', json);
    writer = readDataFromJson('writer', json);
    writtenAt = readDataFromJson('writtenAt', json);
    replyTo = readDataFromJson('replyTo', json);
    updatedAt = readDataFromJson('updatedAt', json);
    id = readDataFromJson('id', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('message', message, payload);
    insertData('channel', channel, payload);
    insertData('writer', writer, payload);
    insertData('writtenAt', writtenAt, payload);
    insertData('replyTo', replyTo, payload);
    insertData('updatedAt', updatedAt, payload);
    insertData('id', id, payload);

    return payload;
  }
}

class ChannelCategoryData implements DocumentData {
  String? name;
  String? desc;
  List<String>? channels;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson('name', json);
    desc = readDataFromJson('desc', json);
    channels = readDataArrayFromJson<String>('channels', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('name', name, payload);
    insertData('desc', desc, payload);
    insertDataArray('channels', channels, payload);

    return payload;
  }
}

class Channels extends Collection<ChannelData> {
  @override
  String get type => 'Channels';

  @override
  Document<ChannelData> add(DocumentData values) {
    throw UnimplementedError();
  }

  Document<ChannelData> addId(DocumentData values, String clientId) {
    return addSimpleDocument(type, 'v1/chat/channel', values, overrideId: clientId);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/chat/channel', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<ChannelData>> get(String id) async {
    return getSimpleDocument(id, 'v1/chat/channel', type, (data) => ChannelData()..constructFromJson(data.content), () => ChannelData());
  }

  @override
  Future<List<Document<ChannelData>>> getAll({bool bForceOffline = false}) async {
    final collection = await getCollection<ChannelData>('v1/chat/channels', '', type, bForceOffline: bForceOffline);

    List<Document<ChannelData>> channels = collection.data
        .map<Document<ChannelData>>((e) => Document(e['exists'], e['id'], ChannelData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(channels);
    }
    return channels;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/chat/channel', documentId, values);
  }
}

class ChannelCategories extends Collection<ChannelCategoryData> {
  @override
  String get type => 'ChatCategories';

  @override
  Document<ChannelCategoryData> add(DocumentData values) {
    throw UnimplementedError();
  }

  Document<ChannelCategoryData> addId(DocumentData values, String clientId) {
    return addSimpleDocument(type, 'v1/chat/category', values, overrideId: clientId);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/chat/category', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<ChannelCategoryData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/chat/category', type, (data) => ChannelCategoryData()..constructFromJson(data.content), () => ChannelCategoryData());
  }

  @override
  Future<List<Document<ChannelCategoryData>>> getAll() async {
    final collection = await getCollection<ChannelCategoryData>('v1/chat/categories', '', type);

    List<Document<ChannelCategoryData>> channels = collection.data
        .map<Document<ChannelCategoryData>>((e) => Document(e['exists'], e['id'], ChannelCategoryData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(channels);
    }
    return channels;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/chat/category', documentId, values);
  }
}

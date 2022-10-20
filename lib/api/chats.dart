import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
    name = readDataFromJson("name", json);
    color = readDataFromJson("color", json);
    desc = readDataFromJson("desc", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("color", color, payload);
    insertData("desc", desc, payload);

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
    message = readDataFromJson("message", json);
    channel = readDataFromJson("channel", json);
    writer = readDataFromJson("writer", json);
    writtenAt = readDataFromJson("writtenAt", json);
    replyTo = readDataFromJson("replyTo", json);
    updatedAt = readDataFromJson("updatedAt", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("message", message, payload);
    insertData("channel", channel, payload);
    insertData("writer", writer, payload);
    insertData("writtenAt", writtenAt, payload);
    insertData("replyTo", replyTo, payload);
    insertData("updatedAt", updatedAt, payload);

    return payload;
  }
}

class ChatMessageDataId extends ChatMessageData {
  String? id;

  ChatMessageDataId(ChatMessageData data, String inId) {
    message = data.message;
    channel = data.channel;
    writer = data.writer;
    writtenAt = data.writtenAt;
    replyTo = data.replyTo;
    updatedAt = data.updatedAt;
    id = inId;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    message = readDataFromJson("message", json);
    channel = readDataFromJson("channel", json);
    writer = readDataFromJson("writer", json);
    writtenAt = readDataFromJson("writtenAt", json);
    replyTo = readDataFromJson("replyTo", json);
    updatedAt = readDataFromJson("updatedAt", json);
    id = readDataFromJson("id", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("message", message, payload);
    insertData("channel", channel, payload);
    insertData("writer", writer, payload);
    insertData("writtenAt", writtenAt, payload);
    insertData("replyTo", replyTo, payload);
    insertData("updatedAt", updatedAt, payload);
    insertData("id", id, payload);

    return payload;
  }
}

class ChannelCategoryData implements DocumentData {
  String? name;
  String? desc;
  List<String>? channels;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    channels = readDataArrayFromJson<String>("channels", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertDataArray("channels", channels, payload);

    return payload;
  }
}

class Channels extends Collection<ChannelData> {
  @override
  String get type => "Channels";

  @override
  Document<ChannelData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/chat/channel", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/chat/channel", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<ChannelData>> get(String id) async {
    return getSimpleDocument(id, "v1/chat/channel", type, (data) => ChannelData()..constructFromJson(data.content), () => ChannelData());
  }

  @override
  Future<List<Document<ChannelData>>> getAll() async {
    var collection = await getCollection<ChannelData>("v1/chat/channels", "", type);

    List<Document<ChannelData>> polls = collection.data.map<Document<ChannelData>>((e) => Document(e["exists"], e["id"], ChannelData()..constructFromJson(e["content"]), type)).toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(polls);
    }
    return polls;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/chat/channel", documentId, values);
  }
}

class ChannelCategories extends Collection<ChannelCategoryData> {
  @override
  String get type => "ChatCategories";

  @override
  Document<ChannelCategoryData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/chat/category", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/chat/category", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<ChannelCategoryData>> get(String id) async {
    return getSimpleDocument(id, "v1/chat/category", type, (data) => ChannelCategoryData()..constructFromJson(data.content), () => ChannelCategoryData());
  }

  @override
  Future<List<Document<ChannelCategoryData>>> getAll() async {
    var collection = await getCollection<ChannelCategoryData>("v1/chat/categories", "", type);

    List<Document<ChannelCategoryData>> polls = collection.data.map<Document<ChannelCategoryData>>((e) => Document(e["exists"], e["id"], ChannelCategoryData()..constructFromJson(e["content"]), type)).toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(polls);
    }
    return polls;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/chat/category", documentId, values);
  }
}

class ChatMessages extends AbstractModel {
  String categoryId = "";

  void setCategoryId(String id) => categoryId = id;

  List<ChatMessageDataId> _recentMessages = [];

  List<ChatMessageDataId> getRecentMessages() => _recentMessages;

  Future<Document<ChatMessageData>?> getMessage(String msgId) async {
    var response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("v1/chat/message/$msgId", ""))).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      var decoded = jsonDecode(response.body) as Map<String, dynamic>;
      ChatMessageData data = ChatMessageData()..constructFromJson(decoded["content"]);

      Document<ChatMessageData> doc = Document<ChatMessageData>(true, msgId, data, "chatMessages");
      return doc;
    }

    return null;
  }

  Future<List<Document<ChatMessageData>>> getMessages(int start, int amount, String? skipTo, bool bOlder, bool bFallbackToCache) async {
    String order = bOlder ? "-1" : "1";

    String query = "limit=$amount&sortBy=writtenAt&sortOrder=$order";

    if (skipTo != null) {
      query += "&skipTo=$skipTo";
    } else {
      query += "&skip=$start";
    }

    var response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("v1/chat/messages/$categoryId", query))).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      CollectionResponse<ChatMessageData> collection = CollectionResponse<ChatMessageData>();
      collection.useOffline = false;
      collection.data = convertServerResponseToList(response);
      return collection.data.map<Document<ChatMessageData>>((e) => Document(e["exists"], e["id"], ChatMessageData()..constructFromJson(e["content"]), "chatMessages")).toList();
    } else if (bFallbackToCache) {
      return getRecentMessages().map((e) => Document<ChatMessageData>(true, e.id!, e, "chatMessages")).toList();
    }

    return [];
  }

  Document<ChatMessageData> writeMessage(ChatMessageData data) {
    String generatedId = ObjectId(clientMode: true).toHexString();

    Map<String, dynamic> jsonPayload = data.toJson();
    API().network().request(new NetworkRequest(HttpRequestMethod.Post, "v1/chat/message/$generatedId", DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));

    _insertMessageToCache(data, generatedId, false);

    notifyListeners();

    return Document(true, generatedId, data, "chatMessages");
  }

  Document<ChatMessageData> updateMessage(Document<ChatMessageData> message) {
    Map<String, dynamic> jsonPayload = message.dataObject.toJson();
    API().network().request(new NetworkRequest(HttpRequestMethod.Patch, "v1/chat/message/${message.id}", DateTime.now().millisecondsSinceEpoch, payload: jsonPayload));

    notifyListeners();

    _insertMessageToCache(message.dataObject, message.id, true);

    // Limit to caching 1000 messages, we don't want to store endlessly
    if (_recentMessages.length > 1000) {
      _recentMessages.removeAt(0);
    }

    return Document(true, message.id, message.dataObject, "chatMessages");
  }

  void deleteMessage(Document<ChatMessageData> message) {
    API().network().request(new NetworkRequest(HttpRequestMethod.Delete, "v1/chat/message/${message.id}", DateTime.now().millisecondsSinceEpoch));

    _recentMessages.removeWhere((element) => element.id == message.id);
    notifyListeners();

    return;
  }

  void cacheMessages(List<Document<ChatMessageData>> listToCache) {
    listToCache.forEach((toCache) => _insertMessageToCache(toCache.dataObject, toCache.id, false));
    sortMessages();
  }

  void sortMessages() {
    _recentMessages.sort((a, b) => b.writtenAt! - a.writtenAt!);
  }

  void _insertMessageToCache(ChatMessageData data, String id, bool bUpdateOnly) {
    int previouslyCachedMessageIndex = _recentMessages.indexWhere((element) => element.id == id);
    if (previouslyCachedMessageIndex >= 0) {
      ChatMessageData oldData = _recentMessages[previouslyCachedMessageIndex];

      // Copy old data such as channel, written at, reply to and writer as those can't change and we don't
      // want to accidentally write an empty message
      ChatMessageData newData = ChatMessageData()
        ..channel = oldData.channel
        ..writtenAt = oldData.writtenAt
        ..replyTo = oldData.replyTo
        ..writer = oldData.writer
        ..message = data.message
        ..updatedAt = data.updatedAt;

      _recentMessages[previouslyCachedMessageIndex] = ChatMessageDataId(newData, id);
    } else if (!bUpdateOnly) {
      _recentMessages.insert(0, ChatMessageDataId(data, id));

      // Limit to caching 50 messages, we don't want to store endlessly
      if (_recentMessages.length > 50) {
        _recentMessages.removeAt(_recentMessages.length - 50); // Kick the oldest
      }
    }

    notifyListeners();
  }

  @override
  copyFromJson(Map<String, dynamic> json) {
    _recentMessages = (json['messages'] as List<dynamic>).map((json) => ChatMessageDataId(ChatMessageData()..constructFromJson(json), json["id"])).toList();
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return {"messages": _recentMessages};
  }

  @override
  void reset([bool notify = true]) {
    copyFromJson({});
    super.reset(notify);
  }

  @override
  String getFileName() {
    return 'messages_$categoryId';
  }
}

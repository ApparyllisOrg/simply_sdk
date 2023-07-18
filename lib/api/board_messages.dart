import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

import '../simply_sdk.dart';

class BoardMessageData implements DocumentData {
  String? title;
  String? message;
  String? writtenBy;
  String? writtenFor;
  bool? read;
  int? writtenAt;
  bool? supportMarkdown;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('title', title, payload);
    insertData('message', message, payload);
    insertData('writtenBy', writtenBy, payload);
    insertData('writtenFor', writtenFor, payload);
    insertData('read', read, payload);
    insertData('writtenAt', writtenAt, payload);
    insertData('supportMarkdown', supportMarkdown, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    title = readDataFromJson('title', json);
    message = readDataFromJson('message', json);
    writtenBy = readDataFromJson('writtenBy', json);
    writtenFor = readDataFromJson('writtenFor', json);
    read = readDataFromJson('read', json);
    writtenAt = readDataFromJson('writtenAt', json);
    supportMarkdown = readDataFromJson('supportMarkdown', json);
  }
}

class BoardMessages extends Collection<BoardMessageData> {
  @override
  String get type => 'BoardMessages';

  @override
  Document<BoardMessageData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/board', values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/board', documentId, originalDocument.dataObject);
    API().store().getFronters().removeWhere((element) => element.dataObject.member == documentId);
  }

  @override
  Future<Document<BoardMessageData>> get(String id) async {
    return getSimpleDocument(
        id, 'v1/board/${API().auth().getUid()}', type, (data) => BoardMessageData()..constructFromJson(data.content), () => BoardMessageData());
  }

  Future<List<Document<BoardMessageData>>> getUnreadMessages() async {
    final collection = await getCollection<BoardMessageData>('v1/board/unread', '', type, skipCache: true);

    // Get all unread messages from cache
    if (collection.useOffline) {
      final Map<String, dynamic> cachedMessages = API().cache().getTypeCache(type);

      final List<Map<String, dynamic>> data = [];

      cachedMessages.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          data.add({'exists': true, 'id': key, 'content': value});
        }
      });

      final List<Document<BoardMessageData>> cachedMessagesList = collection.data
          .map<Document<BoardMessageData>>((e) => Document(e['exists'], e['id'], BoardMessageData()..constructFromJson(e['content']), type))
          .toList();

      return cachedMessagesList.where((element) => element.dataObject.read == false).toList();
    }

    final List<Document<BoardMessageData>> messages = collection.data
        .map<Document<BoardMessageData>>((e) => Document(e['exists'], e['id'], BoardMessageData()..constructFromJson(e['content']), type))
        .toList();

    return messages;
  }

  @override
  Future<List<Document<BoardMessageData>>> getAll({String? uid, int? since, bool bForceOffline = false}) async {
    final collection = await getCollection<BoardMessageData>("v1/board/${(uid ?? API().auth().getUid()) ?? ""}", '', type,
        since: since, bForceOffline: bForceOffline);

    final List<Document<BoardMessageData>> messages = collection.data
        .map<Document<BoardMessageData>>((e) => Document(e['exists'], e['id'], BoardMessageData()..constructFromJson(e['content']), type))
        .toList();
    if (!collection.useOffline) {
      if ((uid ?? API().auth().getUid()) == API().auth().getUid()) {
        API().cache().clearTypeCache(type);
        API().cache().cacheListOfDocuments(messages);
      }
    }
    return messages;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/board', documentId, values);
  }
}

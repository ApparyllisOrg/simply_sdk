import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class NoteData implements DocumentData {
  String? title;
  String? note;
  String? color;
  String? member;
  int? date;
  bool? supportMarkdown;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('title', title, payload);
    insertData('note', note, payload);
    insertData('color', color, payload);
    insertData('member', member, payload);
    insertData('date', date, payload);
    insertData('supportMarkdown', supportMarkdown, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    title = readDataFromJson('title', json);
    note = readDataFromJson('note', json);
    color = readDataFromJson('color', json);
    member = readDataFromJson('member', json);
    date = readDataFromJson('date', json);
    supportMarkdown = readDataFromJson('supportMarkdown', json);
  }
}

class Notes extends Collection<NoteData> {
  @override
  String get type => 'Notes';

  @override
  Document<NoteData> add(DocumentData values) {
    return addSimpleDocument(type, 'v1/note', values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, 'v1/note', documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<NoteData>> get(String id) async {
    return getSimpleDocument(id, 'v1/note/${API().auth().getUid()}', type, (data) => NoteData()..constructFromJson(data.content), () => NoteData());
  }

  @override
  Future<List<Document<NoteData>>> getAll() async {
    final collection = await getCollection<NoteData>('v1/notes/${API().auth().getUid()}', '', type);

    List<Document<NoteData>> notes =
        collection.data.map<Document<NoteData>>((e) => Document(e['exists'], e['id'], NoteData()..constructFromJson(e['content']), type)).toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(notes);
    }
    return notes;
  }

  Future<List<Document<NoteData>>> getNotesForMember(String member, String systemId) async {
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    final response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl('v1/notes/$systemId/$member', '')))
        .catchError((e) => generateFailedResponse(e));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> convertedResponse = convertServerResponseToList(response);
      List<Document<NoteData>> notes = convertedResponse
          .map<Document<NoteData>>((e) => Document(e['exists'], e['id'], NoteData()..constructFromJson(e['content']), type))
          .toList();
      API().cache().cacheListOfDocuments(notes);
      return notes;
    }

    return API().cache().getDocumentsWhere<NoteData>(type, (Document<NoteData> data) {
      return data.dataObject.member == member;
    }, (Map<String, dynamic> data) => NoteData()..constructFromJson(data));
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, 'v1/note', documentId, values);
  }
}

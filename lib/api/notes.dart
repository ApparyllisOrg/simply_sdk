import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
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

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("title", title, payload);
    insertData("note", note, payload);
    insertData("color", color, payload);
    insertData("member", member, payload);
    insertData("date", date, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    title = readDataFromJson("title", json);
    note = readDataFromJson("note", json);
    color = readDataFromJson("color", json);
    member = readDataFromJson("member", json);
    date = readDataFromJson("date", json);
  }
}

class Notes extends Collection {
  @override
  String get type => "Notes";

  @override
  Document<NoteData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/note", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/note", documentId);
  }

  @override
  Future<Document<NoteData>> get(String id) async {
    return getSimpleDocument(id, "v1/note/${API().auth().getUid()}", type, (data) => NoteData()..constructFromJson(data.content), () => NoteData());
  }

  @override
  Future<List<Document<NoteData>>> getAll() async {
    var collection = await getCollection<NoteData>("v1/notes/${API().auth().getUid()}", "");

    List<Document<NoteData>> notes = collection.map<Document<NoteData>>((e) => Document(e["exists"], e["id"], NoteData()..constructFromJson(e["content"]), type)).toList();

    return notes;
  }

  Future<List<Document<NoteData>>> getNotesForMember(String member, String systemId) async {
    var response = await SimplyHttpClient().get(Uri.parse('v1/notes/$systemId/$member'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/note", documentId, values);
  }
}

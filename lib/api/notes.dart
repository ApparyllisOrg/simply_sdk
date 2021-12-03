import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class NoteData implements DocumentData {
  String? name;
  String? desc;
  String? color;
  String? member;
  Timestamp? date;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("color", color, payload);
    insertData("member", member, payload);
    insertData("date", date, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
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
    return Document(true, "", NoteData(), type);
  }

  @override
  Future<List<Document<NoteData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/note", documentId, values);
  }
}

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class PollOptionData implements DocumentData {
  String? name;
  String? color;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    color = readDataFromJson("color", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("color", color, payload);

    return payload;
  }
}

class PollVoteData implements DocumentData {
  String? id;
  String? vote;

  @override
  constructFromJson(Map<String, dynamic> json) {
    id = readDataFromJson("id", json);
    vote = readDataFromJson("vote", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("id", id, payload);
    insertData("vote", vote, payload);

    return payload;
  }
}

class PollData implements DocumentData {
  String? name;
  String? desc;
  bool? allowAbstain;
  bool? allowVeto;
  List<PollOptionData>? options;
  List<PollVoteData>? votes;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("allowAbstain", allowAbstain, payload);
    insertData("allowVeto", allowVeto, payload);
    insertData("options", options, payload);
    insertData("votes", votes, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    allowAbstain = readDataFromJson("allowAbstain", json);
    allowVeto = readDataFromJson("allowVeto", json);
    options = readDataFromJson("options", json);
    votes = readDataFromJson("votes", json);
  }
}

class Polls extends Collection {
  @override
  String get type => "Polls";

  @override
  Document<PollData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/poll", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/poll", documentId);
  }

  @override
  Future<Document<PollData>> get(String id) async {
    return Document(true, "", PollData(), type);
  }

  @override
  Future<List<Document<PollData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/poll", documentId, values);
  }
}

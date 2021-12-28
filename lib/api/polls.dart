import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
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
  String? comment;

  @override
  constructFromJson(Map<String, dynamic> json) {
    id = readDataFromJson("id", json);
    vote = readDataFromJson("vote", json);
    comment = readDataFromJson("comment", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("id", id, payload);
    insertData("vote", vote, payload);
    insertData("comment", comment, payload);

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
  bool? custom;
  int? endTime;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    insertData("allowAbstain", allowAbstain, payload);
    insertData("allowVeto", allowVeto, payload);
    insertData("options", options, payload);
    insertData("votes", votes, payload);
    insertData("custom", custom, payload);
    insertData("endTime", endTime, payload);

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
    custom = readDataFromJson("custom", json);
    endTime = readDataFromJson("endTime", json);
  }
}

class Polls extends Collection<PollData> {
  @override
  String get type => "Polls";

  @override
  Document<PollData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/poll", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/poll", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<PollData>> get(String id) async {
    return getSimpleDocument(id, "v1/poll/${API().auth().getUid()}", type, (data) => PollData()..constructFromJson(data.content), () => PollData());
  }

  @override
  Future<List<Document<PollData>>> getAll() async {
    var collection = await getCollection<PollData>("v1/polls/${API().auth().getUid()}", "");

    List<Document<PollData>> polls = collection.map<Document<PollData>>((e) => Document(e["exists"], e["id"], PollData()..constructFromJson(e["content"]), type)).toList();

    return polls;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/poll", documentId, values);
  }
}

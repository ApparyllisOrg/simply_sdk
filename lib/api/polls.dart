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
  bool? supportDescMarkdown;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("desc", desc, payload);
    if (custom != true) {
      insertData("allowAbstain", allowAbstain, payload);
      insertData("allowVeto", allowVeto, payload);
    }
    insertDataArray("options", options, payload);
    insertDataArray("votes", votes, payload);
    insertData("custom", custom, payload);
    insertData("endTime", endTime, payload);
    insertData("supportDescMarkdown", supportDescMarkdown, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    desc = readDataFromJson("desc", json);
    allowAbstain = readDataFromJson("allowAbstain", json);
    allowVeto = readDataFromJson("allowVeto", json);

    options = [];
    votes = [];

    List<dynamic>? _options = readDataFromJson("options", json);
    if (_options != null) {
      _options.forEach((value) {
        options!.add(PollOptionData()..constructFromJson(value as Map<String, dynamic>));
      });
    }

    List<dynamic>? _votes = readDataFromJson("votes", json);
    if (_votes != null) {
      _votes.forEach((value) {
        votes!.add(PollVoteData()..constructFromJson(value as Map<String, dynamic>));
      });
    }

    custom = readDataFromJson("custom", json);
    endTime = readDataFromJson("endTime", json);
    supportDescMarkdown = readDataFromJson("supportDescMarkdown", json);
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
    var collection = await getCollection<PollData>("v1/polls/${API().auth().getUid()}", "", type);

    List<Document<PollData>> polls = collection.data.map<Document<PollData>>((e) => Document(e["exists"], e["id"], PollData()..constructFromJson(e["content"]), type)).toList();
    if (!collection.useOffline) {
      API().cache().clearTypeCache(type);
      API().cache().cacheListOfDocuments(polls);
    }
    return polls;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/poll", documentId, values);
  }
}

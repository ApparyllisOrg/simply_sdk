import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class RepeatedTimerTimeData implements DocumentData {
  int? hour;
  int? minute;

  @override
  constructFromJson(Map<String, dynamic> json) {
    hour = readDataFromJson("hour", json);
    minute = readDataFromJson("minute", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("hour", hour, payload);
    insertData("minute", minute, payload);

    return payload;
  }
}

class RepeatedTimerStartTimeData implements DocumentData {
  int? day;
  int? month;
  int? year;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("day", day, payload);
    insertData("month", month, payload);
    insertData("year", year, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    day = readDataFromJson("day", json);
    month = readDataFromJson("month", json);
    year = readDataFromJson("year", json);
  }
}

class RepeatedTimerData implements DocumentData {
  String? name;
  String? message;
  double? dayInterval;
  RepeatedTimerTimeData? time;
  RepeatedTimerStartTimeData? startTime;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("message", message, payload);
    insertData("dayInterval", dayInterval, payload);
    insertData("time", time, payload);
    insertData("startTime", startTime, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    message = readDataFromJson("message", json);
    dayInterval = readDataFromJson("dayInterval", json);
    time = RepeatedTimerTimeData().constructFromJson(json["time"]);
    startTime = RepeatedTimerStartTimeData().constructFromJson(json["startTime"]);
  }
}

class RepeatedTimers extends Collection {
  @override
  String get type => "RepeatedTimers";

  @override
  Document<RepeatedTimerData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/timer/repeated", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/timer/repeated", documentId);
  }

  @override
  Future<Document<RepeatedTimerData>> get(String id) async {
    return Document(true, "", RepeatedTimerData(), type);
  }

  @override
  Future<List<Document<RepeatedTimerData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/timer/repeated", documentId, values);
  }
}

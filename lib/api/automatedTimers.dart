import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
class AutomatedTimerData implements DocumentData {
  String? name;
  String? message;
  int? action;
  double? delayInHours;
  int? type;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("message", message, payload);
    insertData("action", action, payload);
    insertData("delayInHours", delayInHours, payload);
    insertData("type", type, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    message = readDataFromJson("message", json);
    action = readDataFromJson("action", json);
    delayInHours = readDataFromJson("delayInHours", json);
    type = readDataFromJson("type", json);
  }
}

class AutomatedTimers extends Collection {
  @override
  String get type => "AutomatedTimers";

  @override
  Document<AutomatedTimerData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/timer/aumtomated", values);
  }

  @override
  void delete(String documentId) {
    deleteSimpleDocument(type, "v1/timer/automated", documentId);
  }

  @override
  Future<Document<AutomatedTimerData>> get(String id) async {
    return Document(true, "", AutomatedTimerData(), type);
  }

  @override
  Future<List<Document<AutomatedTimerData>>> getAll() async {
    return [];
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/timer/automated", documentId, values);
  }
}

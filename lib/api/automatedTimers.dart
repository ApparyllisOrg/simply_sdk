import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class AutomatedTimerData implements DocumentData {
  String? name;
  String? message;
  int? action;
  num? delayInHours;
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

class AutomatedTimers extends Collection<AutomatedTimerData> {
  @override
  String get type => "AutomatedTimers";

  @override
  Document<AutomatedTimerData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/timer/automated", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/timer/automated", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<AutomatedTimerData>> get(String id) async {
    return getSimpleDocument(id, "v1/timer/automated/${API().auth().getUid()}", type, (data) => AutomatedTimerData()..constructFromJson(data.content), () => AutomatedTimerData());
  }

  @override
  Future<List<Document<AutomatedTimerData>>> getAll() async {
    var collection = await getCollection<AutomatedTimerData>("v1/timers/automated/${API().auth().getUid()}", "");

    if (!collection.useOffline) {
      List<Document<AutomatedTimerData>> timers = collection.onlineData.map<Document<AutomatedTimerData>>((e) => Document(e["exists"], e["id"], AutomatedTimerData()..constructFromJson(e["content"]), type)).toList();
      API().cache().cacheListOfDocuments(timers);
      return timers;
    }

    return collection.offlineData;
  }

  @override
  void update(String documentId, DocumentData values) {
    updateSimpleDocument(type, "v1/timer/automated", documentId, values);
  }
}

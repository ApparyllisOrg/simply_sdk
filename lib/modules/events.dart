import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/abstractModel.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';

class EventData extends DocumentData {
  String? event;
  int? time;

  EventData(this.event, this.time);

  @override
  constructFromJson(Map<String, dynamic> json) {
    event = readDataFromJson('event', json);
    time = readDataFromJson('time', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('event', event, payload);
    insertData('time', time, payload);

    return payload;
  }
}

class Event extends AbstractModel {
  List<EventData> pendingEvents = [];

  void reportEvent(String event) {
    pendingEvents.add(EventData(event, DateTime.now().millisecondsSinceEpoch));

    if (pendingEvents.length > 9) {
      sendPendingEvents();
    } else {
      save();
    }
  }

  void sendPendingEvents() {
    if (pendingEvents.length > 0) {
      List<Map<String, dynamic>> toSendEvents = pendingEvents.map((e) => {'event': e.event, 'time': e.time}).toList();
      API()
          .network()
          .request(NetworkRequest(HttpRequestMethod.Post, 'v1/event', DateTime.now().millisecondsSinceEpoch, payload: {'events': toSendEvents}));
      pendingEvents.clear();
      save();
    }
  }

  @override
  Future<void> load() async {
    await super.load();
    sendPendingEvents();
  }

  void reportOpen() {
    API().network().request(NetworkRequest(HttpRequestMethod.Post, 'v1/event/open', DateTime.now().millisecondsSinceEpoch));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'events': pendingEvents};
  }

  @override
  copyFromJson(Map<String, dynamic> json) {
    if (json.containsKey('events')) {
      pendingEvents = (json['events'] as List<dynamic>).map((e) {
        if (e is String) {
          return EventData('', 0)..constructFromJson(jsonDecode(e) as Map<String, dynamic>);
        }
        return EventData('', 0)..constructFromJson(e as Map<String, dynamic>);
      }).toList();
    } else {
      pendingEvents = [];
    }
  }

  @override
  String getFileName() {
    return 'events';
  }
}

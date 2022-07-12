import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';

class MessageData implements DocumentData {
  String? title;
  String? message;
  String? answer;
  int? time;

  @override
  constructFromJson(Map<String, dynamic> json) {
    title = readDataFromJson("title", json);
    message = readDataFromJson("message", json);
    answer = readDataFromJson("answer", json);
    time = readDataFromJson("time", json);
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class Messages {
  Future<List<MessageData>> getMessages() async {
    var response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl('v1/messages', ""))).catchError(((e) => generateFailedResponse(e)));

    var jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      List<dynamic> messages = jsonResponse as List<dynamic>;
      List<Map<String, dynamic>> castedMessages = messages.cast<Map<String, dynamic>>();

      return castedMessages.map((value) => MessageData()..constructFromJson(value)).toList();
    } else {
      return [];
    }
  }

  Future<bool> markRead(int time) async {
    var response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl('v1/messages/read', "")), body: {"time": time}).catchError(((e) => generateFailedResponse(e)));

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }
}

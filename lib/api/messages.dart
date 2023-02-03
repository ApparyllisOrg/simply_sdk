import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';

import '../modules/network.dart';

class MessageData implements DocumentData {
  String? title;
  String? message;
  String? answer;
  int? time;

  @override
  constructFromJson(Map<String, dynamic> json) {
    title = readDataFromJson('title', json);
    message = readDataFromJson('message', json);
    answer = readDataFromJson('answer', json);
    time = readDataFromJson('time', json);
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class Messages {
  Future<List<MessageData>> getMessages() async {
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    final response =
        await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl('v1/messages', ''))).catchError(((e) => generateFailedResponse(e)));

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      List<dynamic> messages = jsonResponse as List<dynamic>;
      List<Map<String, dynamic>> castedMessages = messages.cast<Map<String, dynamic>>();

      return castedMessages.map((value) => MessageData()..constructFromJson(value)).toList();
    } else {
      return [];
    }
  }

  void markRead(int time) {
    API()
        .network()
        .request(new NetworkRequest(HttpRequestMethod.Post, 'v1/messages/read', DateTime.now().millisecondsSinceEpoch, payload: {'time': time}));
  }
}

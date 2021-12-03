import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/user.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class FriendsFrontData {
  final String uid;
  final String frontString;
  final String customFrontString;

  FriendsFrontData(this.uid, this.frontString, this.customFrontString);
}

class FriendSettingsData implements DocumentData {
  bool? seeFront;
  bool? seeMembers;
  bool? getFrontNotif;
  bool? trustedFriend;
  bool? getTheirFrontNotif;

  @override
  constructFromJson(Map<String, dynamic> json) {
    seeFront = readDataFromJson("seeFront", json);
    seeMembers = readDataFromJson("seeMembers", json);
    getFrontNotif = readDataFromJson("getFrontNotif", json);
    trustedFriend = readDataFromJson("trustedFriend", json);
    getTheirFrontNotif = readDataFromJson("getTheirFrontNotif", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("seeFront", seeFront, payload);
    insertData("seeMembers", seeMembers, payload);
    insertData("getFrontNotif", getFrontNotif, payload);
    insertData("trustedFriend", trustedFriend, payload);
    insertData("getTheirFrontNotif", getTheirFrontNotif, payload);

    return payload;
  }
}

class Friends {
  Future<RequestResponse> sendFriendRequest(
      String userId, FriendSettingsData settings) async {
    try {
      var response = await SimplyHttpClient().post(
          Uri.parse(API()
              .connection()
              .getRequestUrl("v1/friends/request/add/$userId", "")),
          body: jsonEncode({"settings": settings.toJson()}));

      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> respondToFriendRequest(
      FriendSettingsData settings, bool accepted, String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().post(
            Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friends/request/respond/$userId", "")),
            body: jsonEncode({"settings": settings.toJson()}));

        return createResponseObject(response);
      } catch (e) {}
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> cancelFriendRequest(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().delete(Uri.parse(API()
            .connection()
            .getRequestUrl("v1/friends/request/$userId", "")));

        return createResponseObject(response);
      } catch (e) {}
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> removeFriend(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().delete(Uri.parse(
            API().connection().getRequestUrl("v1/friends/remove/$userId", "")));

        return createResponseObject(response);
      } catch (e) {}
      return createFailResponseObject();
    });
  }

  Future<List<FriendsFrontData>> getFriendFrontValues() {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().get(Uri.parse(
            API().connection().getRequestUrl("v1/friends/getFrontValues", "")));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          List<Map<String, String>> results = jsonResponse["results"];

          List<FriendsFrontData> friendFronts = [];

          for (var i = 0; i < results.length; ++i) {
            var result = results[i];

            friendFronts.add(FriendsFrontData(
                result["uid"] ?? "",
                result["frontString"] ?? "",
                result["customFrontString"] ?? ""));
          }
          return friendFronts;
        } else {
          return [];
        }
      } catch (e) {}
      return [];
    });
  }

  Future<List<String>> getFriendFronters(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().get(Uri.parse(
            API().connection().getRequestUrl("1/fronters/$userId", "")));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return jsonResponse["results"];
        } else {
          return [];
        }
      } catch (e) {}
      return [];
    });
  }

  List<UserData> _convertResponseIntoUsers(Response response) {
    var jsonResponse = jsonDecode(response.body);
    List<Map<String, dynamic>> userResults = jsonResponse["results"];

    List<UserData> users = [];

    for (var i = 0; i < userResults.length; ++i) {
      users.add(UserData().constructFromJson(userResults[i]));
    }

    return users;
  }

  Future<List<UserData>> getFriends() {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().get(
            Uri.parse(API().connection().getRequestUrl("v1/friends/", "")));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return _convertResponseIntoUsers(jsonResponse);
        } else {
          return [];
        }
      } catch (e) {}
      return [];
    });
  }

  Future<List<UserData>> getIncomingFriendRequests() {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().get(Uri.parse(API()
            .connection()
            .getRequestUrl("/v1/friends/requests/incoming", "")));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return _convertResponseIntoUsers(jsonResponse);
        } else {
          return [];
        }
      } catch (e) {}
      return [];
    });
  }

  Future<List<UserData>> getOutgoingFriendRequests() {
    return Future(() async {
      try {
        var response = await SimplyHttpClient().get(Uri.parse(API()
            .connection()
            .getRequestUrl("/v1/friends/requests/outgoing", "")));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return _convertResponseIntoUsers(jsonResponse);
        } else {
          return [];
        }
      } catch (e) {}
      return [];
    });
  }
}
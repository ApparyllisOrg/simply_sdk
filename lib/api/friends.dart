import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/users.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class FriendsFrontData {
  final String uid;
  final String frontString;
  final String customFrontString;

  FriendsFrontData(this.uid, this.frontString, this.customFrontString);
}

class FriendFronters {
  final List<String> fronters;
  final Map<String, String> frontStatuses;

  FriendFronters({required this.fronters, required this.frontStatuses});
}

class FriendSettingsData implements DocumentData {
  bool? seeFront;
  bool? seeMembers;
  bool? getFrontNotif;
  bool? trusted;
  bool? getTheirFrontNotif;
  String? message;

  @override
  constructFromJson(Map<String, dynamic> json) {
    seeFront = readDataFromJson("seeFront", json);
    seeMembers = readDataFromJson("seeMembers", json);
    getFrontNotif = readDataFromJson("getFrontNotif", json);
    trusted = readDataFromJson("trusted", json);
    getTheirFrontNotif = readDataFromJson("getTheirFrontNotif", json);
    message = readDataFromJson("message", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("seeFront", seeFront, payload);
    insertData("seeMembers", seeMembers, payload);
    insertData("getFrontNotif", getFrontNotif, payload);
    insertData("trusted", trusted, payload);
    insertData("getTheirFrontNotif", getTheirFrontNotif, payload);
    insertData("message", message, payload);

    return payload;
  }
}

class Friends {
  Future<RequestResponse> sendFriendRequest(
      String userId, FriendSettingsData settings) async {
    try {
      var response = await SimplyHttpClient()
          .post(
              Uri.parse(API()
                  .connection()
                  .getRequestUrl("v1/friends/request/add/$userId", "")),
              body: jsonEncode({"settings": settings.toJson()}))
          .catchError(((e) => generateFailedResponse(e)));

      return createResponseObject(response);
    } catch (e) {
      Logger.root.fine("sendFriendRequest failed with: " + e.toString());
    }
    return createFailResponseObject();
  }

  Future<RequestResponse> respondToFriendRequest(
      FriendSettingsData settings, bool accepted, String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .post(
                Uri.parse(API().connection().getRequestUrl(
                    "v1/friends/request/respond/$userId",
                    "accepted=${accepted ? 'true' : 'false'}")),
                body: jsonEncode({"settings": settings.toJson()}))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        Logger.root.fine("respondToFriendRequest failed with: " + e.toString());
      }
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> cancelFriendRequest(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .delete(Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friends/request/$userId", "")))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        Logger.root.fine("cancelFriendRequest failed with: " + e.toString());
      }
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> removeFriend(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .delete(Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friends/remove/$userId", "")))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        Logger.root.fine("removeFriend failed with: " + e.toString());
      }
      return createFailResponseObject();
    });
  }

  // Return a front string and custom front string for all friends of self
  Future<List<FriendsFrontData>> getFriendsFrontValues() {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .get(Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friends/getFrontValues", "")))
            .catchError(((e) => generateFailedResponse(e)));

        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          List<dynamic> results = jsonResponse["results"];

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
      } catch (e) {
        Logger.root.fine("getFriendsFrontValues failed with: " + e.toString());
      }
      return [];
    });
  }

  // Return a front string and custom front string of a user
  Future<FriendsFrontData?> getFriendFrontValues(String uid) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .get(Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friend/$uid/getFrontValue", "")))
            .catchError(((e) => generateFailedResponse(e)));
        var jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return FriendsFrontData(uid, jsonResponse["frontString"] ?? "",
              jsonResponse["customFrontString"] ?? "");
        } else {
          return null;
        }
      } catch (e) {
        Logger.root.fine("getFriendFrontValues failed with: " + e.toString());
      }
      return null;
    });
  }

  // Return a list of all fronting member id's of user
  Future<FriendFronters?> getFriendFronters(String userId) {
    return Future(() async {
      try {
        var response = await SimplyHttpClient()
            .get(Uri.parse(API()
                .connection()
                .getRequestUrl("v1/friend/$userId/getFront", "")))
            .catchError(((e) => generateFailedResponse(e)));
        if (response.statusCode == 200) {
          Map<String, dynamic> body =
              jsonDecode(response.body) as Map<String, dynamic>;
          return FriendFronters(
              frontStatuses: (body["statuses"] as Map<String, dynamic>)
                  .cast<String, String>(),
              fronters: (body["fronters"] as List<dynamic>).cast<String>());
        } else {
          return null;
        }
      } catch (e) {
        Logger.root.fine("getFriendFronters failed with: " + e.toString());
      }
      return null;
    });
  }

  // Return the friend settings for a friend
  Future<Document<FriendSettingsData>?> getFriend(String uid) async {
    var response = await SimplyHttpClient()
        .get(Uri.parse(API()
            .connection()
            .getRequestUrl('v1/friend/${API().auth().getUid()}/$uid/', "")))
        .catchError(((e) => generateFailedResponse(e)));
    var jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Document(
          true,
          uid,
          FriendSettingsData()..constructFromJson(jsonResponse["content"]),
          "friends");
    } else {
      return null;
    }
  }

  // Return the settings a friend has for us
  Future<Document<FriendSettingsData>?> getFriendSettingsForUs(
      String uid) async {
    var response = await SimplyHttpClient()
        .get(Uri.parse(API()
            .connection()
            .getRequestUrl('v1/friend/$uid/${API().auth().getUid()}', "")))
        .catchError(((e) => generateFailedResponse(e)));
    var jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Document(
          true,
          uid,
          FriendSettingsData()..constructFromJson(jsonResponse["content"]),
          "friends");
    } else {
      return null;
    }
  }

  // Update the settings for a friend
  void updateFriend(String uid, FriendSettingsData settings) async {
    API().network().request(new NetworkRequest(HttpRequestMethod.Patch,
        'v1/friend/$uid', DateTime.now().millisecondsSinceEpoch,
        payload: settings.toJson()));
  }

  // Return a list of all friends and their user data
  Future<List<Document<UserData>>> getFriends() {
    return Future(() async {
      var collection = await getCollection<UserData>("v1/friends", "", "Users",
          skipCache: true);

      List<Document<UserData>> friends = collection.data
          .map<Document<UserData>>((e) => Document(e["exists"], e["id"],
              UserData()..constructFromJson(e["content"]), "friends"))
          .toList();

      return friends;
    });
  }

  Future<List<Document<UserData>>> getIncomingFriendRequests() {
    return Future(() async {
      var collection = await getCollection<UserData>(
          "v1/friends/requests/incoming", "", "Users",
          skipCache: true);

      List<Document<UserData>> friends = collection.data
          .map<Document<UserData>>((e) => Document(e["exists"], e["id"],
              UserData()..constructFromJson(e["content"]), "friends"))
          .toList();

      return friends;
    });
  }

  Future<List<Document<UserData>>> getOutgoingFriendRequests() {
    return Future(() async {
      var collection = await getCollection<UserData>(
          "v1/friends/requests/outgoing", "", "Users",
          skipCache: true);

      List<Document<UserData>> friends = collection.data
          .map<Document<UserData>>((e) => Document(e["exists"], e["id"],
              UserData()..constructFromJson(e["content"]), "friends"))
          .toList();

      return friends;
    });
  }
}

import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';

import '../simply_sdk.dart';

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
  Future<void> sendFriendRequest(
      String userid, FriendSettingsData settings) async {
    try {
      await SimplyHttpClient().post(
          Uri.parse(API()
              .connection()
              .getRequestUrl("v1/friends/request/add/$userid", "")),
          body: jsonEncode({"settings": settings.toJson()}));
    } catch (e) {}
    return;
  }

  Future<Map<String, dynamic>> respondToFriendRequest(
      Map<String, dynamic> settings, bool accepted) {
    return Future(() async {
      String url = API().connection().currentHost + "/respondToFriendRqV2";
      http.Response msg = await http
          .post(Uri.parse(url),
              headers: {
                "Authorization": API().auth().getToken(),
                "Content-Type": "application/json"
              },
              body: jsonEncode({"settings": settings, "accept": accepted}))
          .timeout(Duration(seconds: 20), onTimeout: () {
        return Future.error({"success": false, "msg": "Request timed out"});
      }).catchError((e) {
        return Future.error({"success": false, "msg": e});
      });
      return jsonDecode(msg.body);
    });
  }

  Future<Map<String, dynamic>> cancelFriendRequest(String userid) {
    return Future(() async {
      String url = API().connection().currentHost + "/cancelFriendRq";
      http.Response msg = await http
          .post(Uri.parse(url),
              headers: {
                "Authorization": API().auth().getToken(),
                "Content-Type": "application/json"
              },
              body: jsonEncode({"target": target}))
          .timeout(Duration(seconds: 20), onTimeout: () {
        return Future.error({"success": false, "msg": "Request timed out"});
      }).catchError((e) {
        return Future.error({"success": false, "msg": e});
      });
      return jsonDecode(msg.body);
    });
  }

  Future<Map<String, dynamic>> removeFriend(String userid) {
    return Future(() async {
      String url = API().connection().currentHost + "/removeFriend";
      http.Response msg = await http
          .post(Uri.parse(url),
              headers: {
                "Authorization": API().auth().getToken(),
                "Content-Type": "application/json"
              },
              body: jsonEncode({"target": target}))
          .timeout(Duration(seconds: 20), onTimeout: () {
        return Future.error({"success": false, "msg": "Request timed out"});
      }).catchError((e) {
        return Future.error({"success": false, "msg": e});
      });
      return jsonDecode(msg.body);
    });
  }

  FutureOr<dynamic> getFriendFrontValues() {
    return Future(() async {
      String url = API().connection().currentHost + "/friends/getFrontValues";
      http.Response msg = await http.get(Uri.parse(url), headers: {
        "Authorization": API().auth().getToken(),
        "Content-Type": "application/json"
      }).timeout(Duration(seconds: 3), onTimeout: () {
        return http.Response.bytes([], 408);
      }).catchError((e) {
        return {"success": false, "msg": e};
      });
      if (msg.statusCode == 408)
        return {"success": false, "msg": "Request timed out"};
      return {"success": true, "msg": jsonDecode(msg.body)};
    });
  }
}

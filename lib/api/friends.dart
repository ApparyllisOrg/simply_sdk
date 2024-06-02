import 'dart:async';
import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/privacyBuckets.dart';
import 'package:simply_sdk/api/users.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class FriendsFrontData {
  FriendsFrontData(this.uid, this.frontString, this.customFrontString);
  final String uid;
  final String frontString;
  final String customFrontString;
}

class FriendFronters {
  FriendFronters({required this.fronters, required this.frontStatuses});
  final List<String> fronters;
  final Map<String, String> frontStatuses;
}

class FriendSettingsData implements DocumentData, PrivacyBucketInterface {
  String? frienduid;
  bool? seeFront;
  bool? seeMembers;
  bool? getFrontNotif;
  bool? getTheirFrontNotif;
  String? message;
  List<String>? buckets;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    frienduid = readDataFromJson('frienduid', json);
    seeFront = readDataFromJson('seeFront', json);
    seeMembers = readDataFromJson('seeMembers', json);
    getFrontNotif = readDataFromJson('getFrontNotif', json);
    getTheirFrontNotif = readDataFromJson('getTheirFrontNotif', json);
    message = readDataFromJson('message', json);
    buckets = readDataArrayFromJson('buckets', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('seeFront', seeFront, payload);
    insertData('seeMembers', seeMembers, payload);
    insertData('getFrontNotif', getFrontNotif, payload);
    insertData('getTheirFrontNotif', getTheirFrontNotif, payload);
    insertData('message', message, payload);

    return payload;
  }

  @override
  List<String> getBuckets() {
    return buckets ?? [];
  }

  @override
  void setBuckets(List<String> inBuckets) {
    buckets = inBuckets;
  }
}

class Friends {
  Future<RequestResponse> sendFriendRequest(String userId, FriendSettingsData settings) async {
    try {
      final response = await SimplyHttpClient()
          .post(Uri.parse(API().connection().getRequestUrl('v2/friends/request/add/$userId', '')), body: jsonEncode({'settings': settings.toJson()}))
          .catchError(((e) => generateFailedResponse(e)));

      return createResponseObject(response);
    } catch (e) {
      API().debug().logFine('sendFriendRequest failed with: $e');
    }
    return createFailResponseObject();
  }

  Future<RequestResponse> respondToFriendRequest(FriendSettingsData settings, bool accepted, String userId) {
    return Future(() async {
      try {
        final response = await SimplyHttpClient()
            .post(Uri.parse(API().connection().getRequestUrl('v1/friends/request/respond/$userId', "accepted=${accepted ? 'true' : 'false'}")),
                body: jsonEncode({'settings': settings.toJson()}))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        API().debug().logFine('respondToFriendRequest failed with: $e');
      }
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> cancelFriendRequest(String userId) {
    return Future(() async {
      try {
        final response = await SimplyHttpClient()
            .delete(Uri.parse(API().connection().getRequestUrl('v1/friends/request/$userId', '')))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        API().debug().logFine('cancelFriendRequest failed with: $e');
      }
      return createFailResponseObject();
    });
  }

  Future<RequestResponse> removeFriend(String userId) {
    return Future(() async {
      try {
        final response = await SimplyHttpClient()
            .delete(Uri.parse(API().connection().getRequestUrl('v1/friends/remove/$userId', '')))
            .catchError(((e) => generateFailedResponse(e)));

        return createResponseObject(response);
      } catch (e) {
        API().debug().logFine('removeFriend failed with: $e');
      }
      return createFailResponseObject();
    });
  }

  // Return a front string and custom front string for all friends of self
  Future<List<FriendsFrontData>> getFriendsFrontValues() {
    return Future(() async {
      try {
        if (!API().auth().canSendHttpRequests()) {
          await API().auth().waitForAbilityToSendRequests();
        }

        final response = await SimplyHttpClient()
            .get(Uri.parse(API().connection().getRequestUrl('v1/friends/getFrontValues', '')))
            .catchError(((e) => generateFailedResponse(e)));

        final jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          List<dynamic> results = jsonResponse['results'];

          List<FriendsFrontData> friendFronts = [];

          for (var i = 0; i < results.length; ++i) {
            final result = results[i];

            friendFronts.add(FriendsFrontData(result['uid'] ?? '', result['frontString'] ?? '', result['customFrontString'] ?? ''));
          }
          return friendFronts;
        } else {
          return [];
        }
      } catch (e) {
        API().debug().logFine('getFriendsFrontValues failed with: $e');
      }
      return [];
    });
  }

  // Return a front string and custom front string of a user
  Future<FriendsFrontData?> getFriendFrontValues(String uid) {
    return Future(() async {
      try {
        if (!API().auth().canSendHttpRequests()) {
          await API().auth().waitForAbilityToSendRequests();
        }

        final response = await SimplyHttpClient()
            .get(Uri.parse(API().connection().getRequestUrl('v1/friend/$uid/getFrontValue', '')))
            .catchError(((e) => generateFailedResponse(e)));
        final jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return FriendsFrontData(uid, jsonResponse['frontString'] ?? '', jsonResponse['customFrontString'] ?? '');
        } else {
          return null;
        }
      } catch (e) {
        API().debug().logFine('getFriendFrontValues failed with: $e');
      }
      return null;
    });
  }

  // Return a list of all fronting member id's of user
  Future<FriendFronters?> getFriendFronters(String userId) {
    return Future(() async {
      try {
        if (!API().auth().canSendHttpRequests()) {
          await API().auth().waitForAbilityToSendRequests();
        }

        final response = await SimplyHttpClient()
            .get(Uri.parse(API().connection().getRequestUrl('v1/friend/$userId/getFront', '')))
            .catchError(((e) => generateFailedResponse(e)));
        if (response.statusCode == 200) {
          Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
          return FriendFronters(
              frontStatuses: (body['statuses'] as Map<String, dynamic>).cast<String, String>(),
              fronters: (body['fronters'] as List<dynamic>).cast<String>());
        } else {
          return null;
        }
      } catch (e) {
        API().debug().logFine('getFriendFronters failed with: $e');
      }
      return null;
    });
  }

  // Return the friend settings for a friend
  Future<Document<FriendSettingsData>?> getFriend(String uid) async {
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    final response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl('v1/friend/${API().auth().getUid()}/$uid/', '')))
        .catchError(((e) => generateFailedResponse(e)));
    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Document(true, uid, FriendSettingsData()..constructFromJson(jsonResponse['content']), 'friends');
    } else {
      return null;
    }
  }

  // Return the settings a friend has for us
  Future<Document<FriendSettingsData>?> getFriendSettingsForUs(String uid) async {
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    final response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl('v1/friend/$uid/${API().auth().getUid()}', '')))
        .catchError(((e) => generateFailedResponse(e)));
    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Document(true, uid, FriendSettingsData()..constructFromJson(jsonResponse['content']), 'friends');
    } else {
      return null;
    }
  }

  // Update the settings for a friend
  Future<void> updateFriend(String uid, FriendSettingsData settings) async {
    API()
        .network()
        .request(NetworkRequest(HttpRequestMethod.Patch, 'v1/friend/$uid', DateTime.now().millisecondsSinceEpoch, payload: settings.toJson()));
  }

  // Return a list of all friends and their user data
  Future<List<Document<FriendSettingsData>>> getFriendsSettings() {
    return Future(() async {
      final collection = await getCollection<UserData>('v1/friends/settings', '', 'FriendsSettings', skipCache: false);

      final List<Document<FriendSettingsData>> friends = collection.data
          .map<Document<FriendSettingsData>>(
              (e) => Document(e['exists'], e['id'], FriendSettingsData()..constructFromJson(e['content']), 'friendsSettings'))
          .toList();

      if (!collection.useOffline) {
        API().cache().clearTypeCache('FriendsSettings');
        API().cache().cacheListOfDocuments(friends);
      }

      return friends;
    });
  }

  // Return a list of all friends and their user data
  Future<List<Document<UserData>>> getFriends() {
    return Future(() async {
      final collection = await getCollection<UserData>('v1/friends', '', 'Friends', skipCache: false);

      List<Document<UserData>> friends = collection.data
          .map<Document<UserData>>((e) => Document(e['exists'], e['id'], UserData()..constructFromJson(e['content']), 'friends'))
          .toList();

      if (!collection.useOffline) {
        API().cache().clearTypeCache('Friends');
        API().cache().cacheListOfDocuments(friends);
      }

      return friends;
    });
  }

  Future<List<Document<UserData>>> getIncomingFriendRequests() {
    return Future(() async {
      final collection = await getCollection<UserData>('v1/friends/requests/incoming', '', 'Friends', skipCache: true);

      List<Document<UserData>> friends = [];
      collection.data.forEach((element) {
        Document<UserData> doc = Document(element['exists'], element['id'], UserData()..constructFromJson(element['content']), 'friends');
        String? msg = element['content']['message'];
        if (msg != null) {
          doc.data['message'] = msg;
        }
        friends.add(doc);
      });

      return friends;
    });
  }

  Future<List<Document<UserData>>> getOutgoingFriendRequests() {
    return Future(() async {
      final collection = await getCollection<UserData>('v1/friends/requests/outgoing', '', 'Friends', skipCache: true);

      List<Document<UserData>> friends = [];
      collection.data.forEach((element) {
        Document<UserData> doc = Document(element['exists'], element['id'], UserData()..constructFromJson(element['content']), 'friends');
        String? msg = element['content']['message'];
        if (msg != null) {
          doc.data['message'] = msg;
        }
        friends.add(doc);
      });

      return friends;
    });
  }
}

import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class UserFieldData implements DocumentData {
  String? name;
  int? order;
  bool? private;
  bool? preventTrusted;
  int? type;

  @override
  constructFromJson(Map<String, dynamic> json) {
    name = readDataFromJson("name", json);
    order = readDataFromJson("order", json);
    private = readDataFromJson("private", json);
    preventTrusted = readDataFromJson("preventTrusted", json);
    type = readDataFromJson("type", json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("name", name, payload);
    insertData("order", order, payload);
    insertData("private", private, payload);
    insertData("preventTrusted", preventTrusted, payload);
    insertData("type", type, payload);

    return payload;
  }
}

class GenerateUserReportDataFh implements DocumentData {
  int? start;
  int? end;
  bool? includesMembers;
  bool? includesCfs;
  int? privacyLevel;

  @override
  constructFromJson(Map<String, dynamic> json) {
    throw UnimplementedError("This is a to-server data object only, we never retrieve this from the server.");
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("start", start, payload);
    insertData("end", end, payload);
    insertData("includesMembers", includesMembers, payload);
    insertData("includesCfs", includesCfs, payload);
    insertData("privacyLevel", privacyLevel, payload);

    return payload;
  }
}

class GenerateUserReportDataCf implements DocumentData {
  int? privacyLevel;

  @override
  constructFromJson(Map<String, dynamic> json) {
    throw UnimplementedError("This is a to-server data object only, we never retrieve this from the server.");
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};
    insertData("privacyLevel", privacyLevel, payload);

    return payload;
  }
}

class GenerateUserReportDataFMem implements DocumentData {
  bool? includeCustomFields;
  int? privacyLevel;

  @override
  constructFromJson(Map<String, dynamic> json) {
    throw UnimplementedError("This is a to-server data object only, we never retrieve this from the server.");
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("includeCustomFields", includeCustomFields, payload);
    insertData("privacyLevel", privacyLevel, payload);

    return payload;
  }
}

class GenerateUserReportData implements DocumentData {
  String? sendTo;
  List<String>? cc;
  GenerateUserReportDataFh? frontHistory;
  GenerateUserReportDataCf? customFronts;
  GenerateUserReportDataFMem? members;

  @override
  constructFromJson(Map<String, dynamic> json) {
    throw UnimplementedError("This is a to-server data object only, we never retrieve this from the server.");
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("sendTo", sendTo, payload);
    insertData("cc", cc, payload);
    insertData("customFronts", customFronts, payload);
    insertData("frontHistory", frontHistory, payload);
    insertData("members", members, payload);

    return payload;
  }
}

class UserData implements DocumentData {
  String? username;
  String? desc;
  bool? isAsystem;
  String? avatarUuid;
  String? color;
  Map<String, UserFieldData>? fields;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    // No need to fill in username, we can't directly set username..
    insertData("desc", desc, payload);
    insertData("isAsystem", isAsystem, payload);
    insertData("avatarUuid", avatarUuid, payload);
    insertData("color", color, payload);
    insertData("fields", fields, payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    username = readDataFromJson("username", json);
    desc = readDataFromJson("desc", json);
    isAsystem = readDataFromJson("isAsystem", json);
    avatarUuid = readDataFromJson("avatarUuid", json);
    color = readDataFromJson("color", json);

    fields = {};

    Map<String, dynamic>? _fields = readDataFromJson("fields", json);
    if (_fields != null) {
      _fields.forEach((key, value) {
        fields![key] = UserFieldData()..constructFromJson(value);
      });
    }
  }
}

class Users extends Collection<UserData> {
  @override
  String get type => "Users";

  @deprecated
  @override
  Document<DocumentData> add(DocumentData values) {
    throw UnimplementedError();
  }

  @deprecated
  @override
  void delete(String documentId, Document originalDocument) {
    throw UnimplementedError();
  }

  @override
  Future<Document<UserData>> get(String id) async {
    return getSimpleDocument(id, "v1/user", "users", (DocumentResponse data) => UserData()..constructFromJson(data.content), () => UserData());
  }

  @deprecated
  @override
  Future<List<Document<UserData>>> getAll() async {
    throw UnimplementedError();
  }

  @override
  void update(String documentId, UserData values) {
    values.username = null;
    updateSimpleDocument(type, "v1/user", documentId, values);
  }

  Future<RequestResponse> setUsername(String newUsername, String userId) async {
    try {
      var response = await SimplyHttpClient().patch(Uri.parse(API().connection().getRequestUrl("v1/user/username/$userId", "")), body: jsonEncode({"username": newUsername}));

      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> generateUserReport(GenerateUserReportData data) async {
    if (data.customFronts == null && data.customFronts == null && data.members == null) {
      return RequestResponse(false, "You must specify at least one generation type");
    }
    try {
      var response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl("v1/user/generateReport", "")), body: jsonEncode(data.toJson()));
      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<void> deleteAccount() async {
    // Todo: Implement this
  }

  //Todo: Add generate user report
}

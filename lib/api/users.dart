import 'dart:convert';

import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/frame.dart';
import 'package:simply_sdk/types/request.dart';

import '../simply_sdk.dart';

class GenerateUserReportDataFh implements DocumentData {
  int? start;
  int? end;
  bool? includesMembers;
  bool? includesCfs;
  bool? includeMembersBucketless;
  bool? includeCustomFrontsBucketless;
  List<String>? memberBuckets;
  List<String>? customFrontBuckets;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    start = readDataFromJson('start', json);
    end = readDataFromJson('end', json);
    includesMembers = readDataFromJson('includesMembers', json);
    includesCfs = readDataFromJson('includesCfs', json);
    includeMembersBucketless = readDataFromJson('includeMembersBucketless', json);
    includeCustomFrontsBucketless = readDataFromJson('includeCustomFrontsBucketless', json);
    memberBuckets = readDataArrayFromJson('memberBuckets', json);
    customFrontBuckets = readDataArrayFromJson('customFrontBuckets', json);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('start', start, payload);
    insertData('end', end, payload);
    insertData('includeMembers', includesMembers, payload);
    insertData('includeCustomFronts', includesCfs, payload);
    insertData('includeMembersBucketless', includeMembersBucketless, payload);
    insertData('includeCustomFrontsBucketless', includeCustomFrontsBucketless, payload);
    insertDataArray('memberBuckets', memberBuckets, payload);
    insertDataArray('customFrontBuckets', customFrontBuckets, payload);

    return payload;
  }
}

class GenerateUserReportDataCf implements DocumentData {
  bool? includeBucketless;
  List<String>? buckets;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    includeBucketless = readDataFromJson('includeBucketless', json);
    buckets = readDataArrayFromJson('buckets', json);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};
    insertData('includeBucketless', includeBucketless, payload);
    insertDataArray('buckets', buckets, payload);

    return payload;
  }
}

class GenerateUserReportDataFMem implements DocumentData {
  bool? includeCustomFields;
   bool? includeBucketless;
  List<String>? buckets;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    includeCustomFields = readDataFromJson('includeCustomFields', json);
    includeBucketless = readDataFromJson('includeBucketless', json);
    buckets = readDataArrayFromJson('buckets', json);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('includeCustomFields', includeCustomFields, payload);
    insertData('includeBucketless', includeBucketless, payload);
    insertDataArray('buckets', buckets, payload);

    return payload;
  }
}

class GeneratedUserReportData implements DocumentData {
  String? url;
  int? createdAt;
  GenerateUserReportData? usedSettings;

  @override
  constructFromJson(Map<String, dynamic> json) {
    url = readDataFromJson('url', json);
    createdAt = readDataFromJson('createdAt', json);

    if (json['usedSettings'] != null) {
      usedSettings = GenerateUserReportData()..constructFromJson(json['usedSettings'] as Map<String, dynamic>);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('url', url, payload);
    insertData('createdAt', createdAt, payload);
    insertData('usedSettings', usedSettings, payload);

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
    if (json['frontHistory'] != null) {
      frontHistory = GenerateUserReportDataFh()..constructFromJson(json['frontHistory'] as Map<String, dynamic>);
    }

    if (json['customFronts'] != null) {
      customFronts = GenerateUserReportDataCf()..constructFromJson(json['customFronts'] as Map<String, dynamic>);
    }

    if (json['members'] != null) {
      members = GenerateUserReportDataFMem()..constructFromJson(json['members'] as Map<String, dynamic>);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('sendTo', sendTo, payload);
    insertData('cc', cc, payload);
    insertData('customFronts', customFronts, payload);
    insertData('frontHistory', frontHistory, payload);
    insertData('members', members, payload);

    return payload;
  }
}

class UserData implements DocumentData {
  String? username;
  String? desc;
  bool? isAsystem;
  String? avatarUuid;
  String? avatarUrl;
  String? color;
  bool? patron;
  bool? plus;
  bool? supportDescMarkdown;

  FrameData? frame;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    // No need to fill in username, but we only fill it for cache purposes
    insertData('username', username, payload);
    insertData('desc', desc, payload);
    insertData('isAsystem', isAsystem, payload);
    insertData('avatarUuid', avatarUuid, payload);
    insertData('avatarUrl', avatarUrl, payload);
    insertData('color', color, payload);
    insertData('supportDescMarkdown', supportDescMarkdown, payload);

    // Only insert patron for cache reasons
    insertData('patron', patron, payload);
    insertData('plus', plus, payload);

    insertData('frame', frame?.toJson(), payload);

    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    username = readDataFromJson('username', json);
    desc = readDataFromJson('desc', json);
    isAsystem = readDataFromJson('isAsystem', json);
    avatarUuid = readDataFromJson('avatarUuid', json);
    avatarUrl = readDataFromJson('avatarUrl', json);
    color = readDataFromJson('color', json);
    patron = readDataFromJson('patron', json);
    plus = readDataFromJson('plus', json);
    supportDescMarkdown = readDataFromJson('supportDescMarkdown', json);

    frame = FrameData()..constructFromOptionalJson(readDataFromJson('frame', json));
  }
}

class Users extends Collection<UserData> {
  @override
  String get type => 'Users';

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
    return getSimpleDocument(id, 'v1/user', 'users', (DocumentResponse data) => UserData()..constructFromJson(data.content), () => UserData());
  }

  @deprecated
  @override
  Future<List<Document<UserData>>> getAll() async {
    throw UnimplementedError();
  }

  @override
  void update(String documentId, UserData values) {
    values.username = null;
    values.patron = null;
    values.plus = null;
    updateSimpleDocument(type, 'v1/user', documentId, values);
  }

  Future<RequestResponse> setUsername(String newUsername, String userId) async {
    try {
      final response = await SimplyHttpClient()
          .patch(Uri.parse(API().connection().getRequestUrl('v1/user/username/$userId', '')), body: jsonEncode({'username': newUsername}))
          .catchError((e) => generateFailedResponse(e));

      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> generateUserReport(GenerateUserReportData data) async {
    if (data.customFronts == null && data.frontHistory == null && data.members == null) {
      return RequestResponse(false, 'You must specify at least one generation type');
    }
    try {
      final response = await SimplyHttpClient()
          .post(Uri.parse(API().connection().getRequestUrl('v2/user/generateReport', '')), body: jsonEncode(data.toJson()))
          .catchError((e) => generateFailedResponse(e));
      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> deleteAccount() async {
    try {
      final response = await SimplyHttpClient()
          .delete(Uri.parse(API().connection().getRequestUrl('v1/user/${API().auth().getUid()}', '')), body: jsonEncode({'performDelete': true}))
          .catchError((e) => createResponseObject(e));
      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> deleteUserReport(String reportId) async {
    try {
      final response = await SimplyHttpClient()
          .delete(Uri.parse(API().connection().getRequestUrl('v1/user/${API().auth().getUid()}/report/$reportId', '')))
          .catchError((e) => createResponseObject(e));
      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }

  Future<RequestResponse> exportData() async {
    try {
      final response = await SimplyHttpClient()
          .post(Uri.parse(API().connection().getRequestUrl('v1/user/${API().auth().getUid()}/export', '')))
          .catchError((e) => createResponseObject(e));
      return createResponseObject(response);
    } catch (e) {}
    return createFailResponseObject();
  }
}

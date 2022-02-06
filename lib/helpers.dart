import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/simply_sdk.dart';

import 'api/members.dart';
import 'modules/collection.dart';

enum EUpdateType { Add, Update, Remove }

String updateTypeToString(EUpdateType type) {
  switch (type) {
    case EUpdateType.Add:
      return "insert";
    case EUpdateType.Update:
      return "update";
    case EUpdateType.Remove:
      return "delete";
  }

  return "";
}

dynamic getHeader() => {"Content-Type": "application/json", "Authorization": API().auth().getToken()};

dynamic customEncode(var obj) {
  if (obj is DateTime) {
    return obj.millisecondsSinceEpoch;
  }
}

Object? customDecode(dynamic key, dynamic value) {
  return value;
}

void insertData(String propertyName, dynamic dataToInsert, Map<String, dynamic> dataObject) {
  if (dataToInsert != null) {
    if (dataToInsert is DocumentData) {
      dataObject[propertyName] = dataToInsert.toJson();
    } else {
      dataObject[propertyName] = dataToInsert;
    }
  }
}

T? readDataFromJson<T>(String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is List) {
    return json[propertyName] as T;
  }
  return json[propertyName] as T?;
}

List<T>? readDataArrayFromJson<T>(String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is List) {
    List<dynamic> array = json[propertyName] as List<dynamic>;
    return array.cast<T>();
  }
  return [];
}

T? readDataMapFromJson<T, K>(String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is Map<String, dynamic>) {
    Map<String, dynamic> map = json[propertyName] as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value as K)) as T;
  }
  return json[propertyName] as T?;
}

DocumentData? convertJsonToDataObject(Map<String, dynamic> json, String type) {
  if (type == "Members") {
    return MemberData().constructFromJson(json);
  }
}

List<Map<String, dynamic>> convertServerResponseToList(Response response) {
  List list = jsonDecode(response.body);
  return list.map((e) => e as Map<String, dynamic>).toList();
}

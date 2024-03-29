import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/request.dart';

import 'modules/collection.dart';

enum EUpdateType { Add, Update, Remove }

String updateTypeToString(EUpdateType type) {
  switch (type) {
    case EUpdateType.Add:
      return 'insert';
    case EUpdateType.Update:
      return 'update';
    case EUpdateType.Remove:
      return 'delete';
  }

  return '';
}

dynamic getHeader() => {
      'Content-Type': 'application/json',
      'Authorization': API().auth().getToken()
    };

dynamic customEncode(var obj) {
  if (obj is DateTime) {
    return obj.millisecondsSinceEpoch;
  }
}

Object? customDecode(dynamic key, dynamic value) {
  return value;
}

void insertData(String propertyName, dynamic dataToInsert,
    Map<String, dynamic> dataObject) {
  if (dataToInsert != null) {
    if (dataToInsert is DocumentData) {
      dataObject[propertyName] = dataToInsert.toJson();
    } else {
      dataObject[propertyName] = dataToInsert;
    }
  }
}

void insertDataArray(String propertyName, List<dynamic>? dataToInsert,
    Map<String, dynamic> dataObject) {
  if (dataToInsert != null) {
    List<dynamic> list = [];
    dataToInsert.forEach((value) {
      if (value is DocumentData) {
        list.add(value.toJson());
      } else {
        list.add(value);
      }
    });
    dataObject[propertyName] = list;
  }
}

void insertDataMap(String propertyName, Map<String, dynamic>? dataToInsert,
    Map<String, dynamic> dataObject) {
  if (dataToInsert != null) {
    Map<String, dynamic> map = {};
    dataToInsert.forEach((key, value) {
      if (value is DocumentData) {
        map[key] = value.toJson();
      } else {
        map[key] = value;
      }
    });
    dataObject[propertyName] = map;
  }
}

T? readDataFromJson<T>(String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is List) {
    return json[propertyName] as T;
  }
  return json[propertyName] as T?;
}

List<T>? readDataArrayFromJson<T>(
    String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is List) {
    List<dynamic> array = json[propertyName] as List<dynamic>;
    return array.cast<T>();
  }
  return [];
}

List<T>? readDataTypeArrayFromJson<T>(
    String propertyName,
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> data) createData) {
  if (json[propertyName] is List) {
    List<dynamic> array = json[propertyName] as List<dynamic>;
    return array
        .map<T>((entry) => createData(entry as Map<String, dynamic>))
        .toList();
  }
  return [];
}

List<Map<String, dynamic>> convertServerResponseToList(Response response) {
  final List list = jsonDecode(response.body) as List;
  return list.map((e) => e as Map<String, dynamic>).toList();
}

String? getAvatarFromDocument(Document<dynamic> doc, String userId) {
  if (doc.data.containsKey("avatarUuid")) {
    String? avatarUuid = doc.data["avatarUuid"];
    if (avatarUuid?.isNotEmpty == true) {
      return 'https://spaces.apparyllis.com/avatars/$userId/$avatarUuid/';
    }
  }

  if (doc.data.containsKey("avatarUrl")) {
    String? avatarUrl = doc.data["avatarUrl"];
    if (avatarUrl?.isNotEmpty == true) {
      return avatarUrl;
    }
  }

  return null;
}

String getResponseText(Response response) {
  if (response.statusCode >= 500 && response.statusCode <= 599) {
    return "Unable to reach the servers, try again later.";
  }

  return response.body;
}

import 'package:cloud_firestore/cloud_firestore.dart';
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
  if (obj is Timestamp) {
    return obj.millisecondsSinceEpoch;
  }
  if (obj is DateTime) {
    return obj.millisecondsSinceEpoch;
  }
}

Object customDecode(dynamic key, dynamic value) {
  if (value is int) {
    if (key is String) {
      if (key.contains("time") || key.contains("date")) {
        return Timestamp.fromMillisecondsSinceEpoch(value);
      }
    }
  }
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

T readDataFromJson<T>(String propertyName, Map<String, dynamic> json) {
  if (json[propertyName] is List) {
    return json[propertyName] as T;
  }
  return json[propertyName] as T;
}

List<T> readDataArrayFromJson<T>(String propertyName, Map<String, dynamic> json) {
  List? oldList = json[propertyName];
  List<T> newList = [];

  oldList?.forEach((element) {
    newList.add(element as T);
  });

  return newList;
}

DocumentData? convertJsonToDataObject(Map<String, dynamic> json, String type) {
  if (type == "Members") {
    return MemberData().constructFromJson(json);
  }
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/simply_sdk.dart';

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

getHeader() => {
      "Content-Type": "application/json",
      "Authorization": API().auth().getToken()
    };

dynamic customEncode(var obj) {
  if (obj is Timestamp) {
    return {"_seconds": obj.seconds, "_nanoseconds": obj.nanoseconds};
  }
  if (obj is DateTime) {
    return {
      "_seconds": obj.millisecondsSinceEpoch / 1000,
      "_nanoseconds": Timestamp.fromDate(obj).nanoseconds
    };
  }
}

Object customDecode(dynamic key, dynamic value) {
  if (key is String) {
    if (key.contains("time") || key.contains("date")) {
      return Timestamp.fromMicrosecondsSinceEpoch(
          (value["_seconds"] * 1000 * 1000) + (value["_nanoseconds"] / 1000));
    }
  }
  return value;
}

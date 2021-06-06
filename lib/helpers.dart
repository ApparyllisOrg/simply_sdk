import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/simply_sdk.dart';

getHeader() => {
      "Content-Type": "application/json",
      "Authorization": API().auth().getToken()
    };

dynamic customEncode(var obj) {
  if (obj is Timestamp) {
    return obj.microsecondsSinceEpoch;
  }
  if (obj is DateTime) {
    return obj.microsecondsSinceEpoch;
  }
}

Object customDecode(dynamic key, dynamic value) {
  if (value is int) {
    if (key is String) {
      if (key.contains("time") || key.contains("date")) {
        return Timestamp.fromMicrosecondsSinceEpoch(value);
      }
    }
  }
  return value;
}

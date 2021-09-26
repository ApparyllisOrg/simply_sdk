import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart';
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

dynamic getHeader() => {
      "Content-Type": "application/json",
      "Authorization": API().auth().getToken()
    };

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

HttpMetric getMetric(Uri url, HttpMethod method) {
  HttpMetric appMetric = API().getHttpMetric(url, method);
  if (appMetric != null) {
    return appMetric;
  }

  HttpMetric metric = FirebasePerformance.instance
      .newHttpMetric(url.toString(), HttpMethod.Post);
  metric.putAttribute("offline", "false");
  metric.start();
  return metric;
}

void metricSuccess(HttpMetric metric) {
  metric.stop();
}

void metricFail(HttpMetric metric) {
  metric.putAttribute("offline", "true");
  metric.stop();
}

void removeField(String field, Map<String, dynamic> data) {
  List<String> fields = field.split(".");

  Map<String, dynamic> local = data;

  for (int i = 0; i < fields.length; i++) {
    if (i == fields.length - 1) {
      local.remove(fields[i]);
    } else {
      local = local[fields[i]];
    }
  }
}

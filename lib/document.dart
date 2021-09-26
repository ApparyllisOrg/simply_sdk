import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

class DocumentRef {
  final String collectionId;
  final String id;

  DocumentRef(this.id, this.collectionId);

  bool operator ==(other) {
    return other is DocumentRef &&
        other.collectionId == collectionId &&
        other.id == id;
  }

  int get hashCode {
    return (collectionId + id).hashCode;
  }
}

class Document {
  bool exists;
  final bool fromCache;
  Map<String, dynamic> data;
  final String collectionId;
  final String id;

  T value<T>(String field, T fallback) {
    // This really shouldn't be null, investigate.
    if (data == null) {
      return fallback;
    }

    var value = data[field];
    if (value != null) {
      // Special case where every DateTime needs to be converted to Timestamp, as
      // we only provide Timestamp to ensure server/cache works in harmony
      if (value is DateTime) {
        return Timestamp.fromDate(value) as T;
      }
      return value as T;
    }
    return fallback;
  }

  static Map<String, dynamic> convertTime(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (key.toLowerCase().contains("time") && value is int) {
        data[key] = Timestamp.fromMillisecondsSinceEpoch(value);
      }
    });
    return data;
  }

  Document(this.exists, this.id, this.collectionId, this.data,
      {this.fromCache = false}) {
    assert(id != null);
    assert(collectionId != null);
    if (data == null) data = {};
    data = convertTime(this.data);
  }

  Future<Response> deleteImpl(int time) async {
    var url = Uri.parse(API().connection().documentDelete());
    var sendData = Map.from(data);
    sendData["target"] = collectionId;
    sendData["id"] = id;
    sendData["deleteTime"] = time;

    final HttpMetric metric = getMetric(url, HttpMethod.Delete);

    var response;
    try {
      response = await http.delete(url,
          headers: getHeader(),
          body: jsonEncode(sendData, toEncodable: customEncode));
    } catch (e) {
      print(e);
    }

    if (response == null) {
      metricFail(metric);
    } else {
      metricSuccess(metric);
    }

    return response;
  }

  Future<Response> updateImpl(Map<String, dynamic> inData, int time) async {
    var url = Uri.parse(API().connection().documentUpdate());

    Map<String, dynamic> sendData = {};
    sendData["target"] = collectionId;
    sendData["id"] = id;
    sendData["content"] = inData;
    sendData["updateTime"] = time;

    final HttpMetric metric = getMetric(url, HttpMethod.Post);

    var response;
    try {
      response = await http.patch(url,
          headers: getHeader(),
          body: jsonEncode(sendData, toEncodable: customEncode));
    } catch (e) {
      print(e);
    }

    if (response == null) {
      metricFail(metric);
    } else {
      metricSuccess(metric);
    }

    return response;
  }

  Future delete() async {
    await API().auth().isAuthenticated();

    API()
        .cache()
        .removeDocument(collectionId, id, doTriggerUpdateSubscription: false);

    API().socket().beOptimistic(collectionId, EUpdateType.Remove, id, data);

    API().cache().queueDelete(collectionId, id);

    return;
  }

  Future update(inData) async {
    await API().auth().isAuthenticated();

    data.addAll(inData);

    API().cache().updateDocument(collectionId, id, data,
        doTriggerUpdateSubscription: false);

    API().socket().beOptimistic(collectionId, EUpdateType.Update, id, data);

    API().cache().queueUpdate(collectionId, id, data);

    API().docSubscriptions().propogateChange(this);

    return;
  }
}

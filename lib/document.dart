import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

class Document {
  bool exists;
  Map<String, dynamic> data;
  final String collectionId;
  final String id;

  T value<T>(String field, T fallback) {
    var value = data[field];
    if (value != null) {
      return value as T;
    }
    return fallback;
  }

  Document(this.exists, this.id, this.collectionId, this.data) {
    assert(id != null);
    assert(collectionId != null);
  }

  Future<Response> deleteImpl() {
    return Future(() async {
      var url = Uri.parse(API().connection().documentDelete());
      var sendData = Map.from(data);
      sendData["target"] = collectionId;
      sendData["id"] = id;

      var response;
      try {
        response = await http.delete(url,
            headers: getHeader(), body: jsonEncode(sendData));
      } catch (e) {}
      return response;
    });
  }

  Future<Response> updateImpl(Map<String, dynamic> inData, int time) {
    return Future(() async {
      var url = Uri.parse(API().connection().documentUpdate());

      Map<String, dynamic> sendData = {};
      sendData["target"] = collectionId;
      sendData["id"] = id;
      sendData["content"] = inData;
      sendData["updateTime"] = time;

      var response;
      try {
        response = await http.patch(url,
            headers: getHeader(),
            body: jsonEncode(sendData, toEncodable: customEncode));
      } catch (e) {}

      return response;
    });
  }

  Future delete() async {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      API().cache().removeDocument(collectionId, id);

      var response = await deleteImpl();

      if (response == null) {
        API().cache().queueDelete(collectionId, id);
        return;
      }

      if (response.statusCode == 200) {
        exists = false;
      } else {
        if (response.statusCode != 400) {
          API().cache().queueDelete(collectionId, id);
        }

        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return;
    });
  }

  Future update(inData) async {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      API().cache().updateDocument(collectionId, id, inData);

      var response =
          await updateImpl(inData, DateTime.now().millisecondsSinceEpoch);

      if (response == null) {
        API().cache().queueUpdate(collectionId, id, inData);
        return;
      }

      if (response.statusCode == 200) {
        data.addAll(inData);
      } else {
        if (response.statusCode != 400) {
          API().cache().queueUpdate(collectionId, id, inData);
        }

        if (response.statusCode == 500) {}
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return;
    });
  }
}

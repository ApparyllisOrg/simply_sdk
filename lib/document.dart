import 'dart:convert';

import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

class Document {
  bool exists;
  Map<String, dynamic> data;
  final String collectionId;
  final String id;

  Document(this.exists, this.id, this.collectionId, this.data) {
    assert(id != null);
    assert(collectionId != null);
  }

  Future delete() async {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      var url = Uri.parse(API().connection().documentDelete());

      var sendData = Map.from(data);
      sendData["target"] = collectionId;
      sendData["id"] = id;

      var response = await http.delete(url,
          headers: getHeader(), body: jsonEncode(sendData));

      if (response.statusCode == 200) {
        exists = false;
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return;
    });
  }

  Future update(inData) async {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      var url = Uri.parse(API().connection().documentUpdate());

      var sendData = {};
      sendData["target"] = collectionId;
      sendData["id"] = id;
      sendData["content"] = inData;

      var response = await http.patch(url,
          headers: getHeader(), body: jsonEncode(sendData));

      if (response.statusCode == 200) {
        data.addAll(inData);
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return;
    });
  }
}

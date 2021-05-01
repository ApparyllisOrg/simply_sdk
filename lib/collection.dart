import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

import 'document.dart';

class Query {
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLargerThan;
  final dynamic isSmallerThan;

  Query(
      {this.isEqualTo,
      this.isNotEqualTo,
      this.isLargerThan,
      this.isSmallerThan});

  String getMethod() {
    if (isEqualTo != null) return "isEqualTo";
    if (isNotEqualTo != null) return "isNotEqualTo";
    if (isLargerThan != null) return "isLargerThan";
    if (isSmallerThan != null) return "isSmallerThan";
    assert(false, "Missing implementation!");
  }

  dynamic getValue() {
    if (isEqualTo != null) return isEqualTo;
    if (isNotEqualTo != null) return isNotEqualTo;
    if (isLargerThan != null) return isLargerThan;
    if (isSmallerThan != null) return isSmallerThan;
    assert(false, "Missing implementation!");
  }
}

class Collection {
  final String id;

  Collection(this.id);

  Map<String, Query> query = {};

  Collection where(Map<String, Query> addQuery) {
    query.addAll(addQuery);
    return this;
  }

  String _getQueryString() {
    Map<String, String> stringifiedQueries = {};
    query.forEach((key, value) {
      assert(value != null);
      var query = {};
      query["method"] = value.getMethod();
      query["value"] = value.getValue();
      stringifiedQueries[key] = jsonEncode(query);
    });
    return jsonEncode(stringifiedQueries);
  }

  Future<List<Document>> get() {
    return Future(() async {
      assert(API().auth().isAuthenticated());
      List<Document> documents = [];

      Map<String, dynamic> urlQuery = {
        "target": id,
        "query": _getQueryString()
      };

      var url = Uri.parse(
          API().connection().collectionGet() + "?" + jsonEncode(urlQuery));

      var response =
          await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        var returnedDocuments = jsonDecode(response.body);
        for (var doc in returnedDocuments) {
          documents.add(Document(true, doc["id"], doc["content"]));
        }
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return documents;
    });
  }

  Future<Document> add(Map<String, dynamic> data) {
    return Future(() async {
      assert(API().auth().isAuthenticated());
      Map<String, dynamic> postBody = {"target": id, "content": data};

      var url = Uri.parse(API().connection().documentAdd());

      var response = await http.post(url,
          body: jsonEncode(postBody),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        var responseObject = jsonDecode(response.body);
        return Document(true, responseObject["id"], data);
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }
    });
  }
}

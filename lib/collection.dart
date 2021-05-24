import 'dart:convert';

import 'package:sembast/sembast.dart';
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

  Map<String, dynamic> getQueryMap() {
    Map<String, dynamic> query = {};
    query["method"] = getMethod();
    query["value"] = getValue();
    return query;
  }

  Filter getFilter(String field) {
    if (isEqualTo != null) return Filter.equals(field, getValue());
    if (isNotEqualTo != null) return Filter.notEquals(field, getValue());
    if (isLargerThan != null) return Filter.greaterThan(field, getValue());
    if (isSmallerThan != null) return Filter.lessThan(field, getValue());
  }
}

class Collection {
  final String id;

  String _orderby;
  int _limit;
  int _start;
  int _end;

  Collection(this.id);

  Map<String, Query> query = {};

  Collection where(Map<String, Query> addQuery) {
    query.addAll(addQuery);
    return this;
  }

  Collection orderBy(String newValue) {
    _orderby = newValue;
    return this;
  }

  Collection limit(int newValue) {
    _limit = newValue;
    return this;
  }

  Collection start(int newValue) {
    _start = newValue;
    return this;
  }

  Future<Document> document(String docId) {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      Document doc = Document(false, docId, id, {});
      print(docId);

      var url = Uri.parse(
          API().connection().documentGet() + "?" + "target=$id&id=$docId");

      var response = await http.get(
        url,
        headers: getHeader(),
      );

      if (response.statusCode == 200) {
        var returnedDocument = jsonDecode(response.body);
        doc.data = returnedDocument["content"];
        doc.exists = returnedDocument["exists"];
      } else {
        doc.data = {};
        doc.exists = false;
        print("${response.statusCode.toString()}: ${response.body}");
      }

      return doc;
    });
  }

  Map<String, dynamic> _getQueryString() {
    Map<String, dynamic> stringifiedQueries = {};
    bool hasUid = false;
    query.forEach((key, value) {
      assert(value != null);
      hasUid |= key == "uid";
      stringifiedQueries[key] = value.getQueryMap();
    });
    if (!hasUid) {
      stringifiedQueries["uid"] =
          Query(isEqualTo: API().auth().getUid()).getQueryMap();
    }
    return stringifiedQueries;
  }

  String _getOrderBy() {
    if (_orderby != null) return "&orderBy=$_orderby";
    return "";
  }

  String _getLimit() {
    if (_limit != null) return "&limit=$_limit";
    return "";
  }

  String _getStart() {
    if (_start != null) return "&start=$_start";
    return "";
  }

  Future<List<Document>> get() {
    return Future(() async {
      assert(API().auth().isAuthenticated());
      List<Document> documents = [];
      var url = Uri.parse(API().connection().collectionGet() +
          "?" +
          "target=$id${_getOrderBy()}${_getLimit()}${_getStart()}&query=" +
          jsonEncode(_getQueryString()));

      var response = await http.get(
        url,
        headers: getHeader(),
      );

      if (response.statusCode == 200) {
        var returnedDocuments = jsonDecode(response.body);
        for (var doc in returnedDocuments) {
          documents.add(Document(true, doc["id"], id, doc["content"]));
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
      Map<String, dynamic> postBody = {
        "target": id,
        "content": data,
        "updateTime": DateTime.now().millisecondsSinceEpoch
      };

      var url = Uri.parse(API().connection().documentAdd());

      var response = await http.post(url,
          body: jsonEncode(postBody), headers: getHeader());

      if (response.statusCode == 200) {
        var responseObject = jsonDecode(response.body);

        return Document(true, responseObject["id"], id, data);
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }
    });
  }
}

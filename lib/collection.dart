import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:sembast/sembast.dart';
import 'package:simply_sdk/helpers.dart';

import 'package:http/http.dart' as http;

import 'document.dart';
import 'simply_sdk.dart';

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

  int getStart() => _start;

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

      var response;
      try {
        response = await http.get(
          url,
          headers: getHeader(),
        );
      } catch (e) {}

      if (response == null) {
        return await API().cache().getDocument(id, docId);
      }

      if (response.statusCode == 200) {
        var returnedDocument = jsonDecode(response.body, reviver: customDecode);

        return Document(returnedDocument["exists"], docId, id,
            returnedDocument["content"] ?? {});
      } else {
        doc.data = {};
        doc.exists = false;
        print("${response.statusCode.toString()}: ${response.body}");
      }

      return doc;
    });
  }

  Future<void> updateDocument(String docId, Map<String, dynamic> data) {
    return Future(() async {
      Document doc = Document(true, docId, id, {});
      await doc.update(data);
    });
  }

  Future<void> deleteDocument(String docId) {
    return Future(() async {
      Document doc = Document(true, docId, id, {});
      await doc.delete();
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

  Future<Document> getOne() {
    return Future(() async {
      List<Document> getResult = await get();
      if (getResult.isNotEmpty) {
        return getResult.first;
      }
      return Document(false, "", id, {});
    });
  }

  Future<List<Document>> get() {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      if (_end != null || _start != null || _limit != null) {
        assert(_orderby != null);
      }

      List<Document> documents = [];
      var url = Uri.parse(API().connection().collectionGet() +
          "?" +
          "target=$id${_getOrderBy()}${_getLimit()}${_getStart()}&query=" +
          jsonEncode(_getQueryString(), toEncodable: customEncode));

      var response;
      try {
        response = await http.get(
          url,
          headers: getHeader(),
        );
      } catch (e) {}

      if (response == null) {
        return await API().cache().searchForDocuments(id, query, _orderby,
            start: _start, end: _limit);
      }

      if (response.statusCode == 200) {
        var returnedDocuments =
            jsonDecode(response.body, reviver: customDecode);
        for (var doc in returnedDocuments) {
          documents.add(Document(true, doc["id"], id, doc["content"] ?? {}));
        }
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return documents;
    });
  }

  Future<List<Document>> getComplex(Map<dynamic, dynamic> query) {
    return Future(() async {
      assert(API().auth().isAuthenticated());

      if (_end != null || _start != null || _limit != null) {
        assert(_orderby != null);
      }

      List<Document> documents = [];
      var url = Uri.parse(API().connection().collectionGetComplex() +
          "?" +
          "target=$id${_getOrderBy()}${_getLimit()}${_getStart()}&query=" +
          jsonEncode(query, toEncodable: customEncode));

      var response;
      try {
        response = await http.get(
          url,
          headers: getHeader(),
        );
      } catch (e) {}

      if (response == null) {
        return [];
      }

      if (response.statusCode == 200) {
        var returnedDocuments =
            jsonDecode(response.body, reviver: customDecode);
        for (var doc in returnedDocuments) {
          documents.add(Document(true, doc["id"], id, doc["content"] ?? {}));
        }
      } else {
        throw ("${response.statusCode.toString()}: ${response.body}");
      }

      return documents;
    });
  }

  Future<Response> addImpl(String docID, Map<String, dynamic> data, int time) {
    return Future(() async {
      var url = Uri.parse(API().connection().documentAdd());

      Map<String, dynamic> postBody = {
        "target": id,
        "content": data,
        "updateTime": time,
        "id": docID
      };

      String decode = jsonEncode(postBody, toEncodable: customEncode);

      var response;
      try {
        response = await http.post(url, body: decode, headers: getHeader());
      } catch (e) {
        print(e);
      }
      return response;
    });
  }

  Future<Document> add(Map<String, dynamic> data, {String customId}) {
    return Future(() async {
      assert(API().auth().isAuthenticated());
      String docID =
          customId != null ? customId : mongo.ObjectId(clientMode: true).$oid;

      API().cache().insertDocument(id, docID, data);

      API().socket().beOptimistic(id, EUpdateType.Add, docID, data);

      var response =
          await addImpl(docID, data, DateTime.now().microsecondsSinceEpoch);

      if (response == null) {
        API().cache().queueAdd(id, docID, data);
        return Document(true, docID, id, data);
      }

      if (response.statusCode == 200) {
        return Document(true, docID, id, data);
      } else {
        if (response.statusCode != 400) {
          API().cache().queueAdd(id, docID, data);
          return Document(true, docID, id, data);
        }
        throw ("${response.statusCode.toString()}: ${response.body}");
      }
    });
  }
}

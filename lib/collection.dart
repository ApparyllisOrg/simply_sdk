import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
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
    return "";
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

  bool isSatisfied(dynamic property) {
    try {
      if (isEqualTo != null) return property == isEqualTo;
      if (isNotEqualTo != null) return property != isNotEqualTo;
      if (isLargerThan != null) return property > isLargerThan;
      if (isSmallerThan != null) return property < isSmallerThan;
      assert(false, "Missing implementation!");
    } catch (e) {
      return false;
    }
    return false;
  }
}

class Collection {
  final String id;

  String _orderby;
  int _orderByOrder;
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

  Collection orderBy(String newValue, int order) {
    _orderby = newValue;
    _orderByOrder = order;
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
      await API().auth().isAuthenticated();

      print(docId);

      var url = Uri.parse(
          API().connection().documentGet() + "?" + "target=$id&id=$docId");

      var response;
      try {
        response = await http
            .get(
              url,
              headers: getHeader(),
            )
            .timeout(Duration(seconds: 5));
      } catch (e) {}

      if (response == null) {
        return await API().cache().getDocument(id, docId);
      }

      if (response.statusCode == 200) {
        var returnedDocument = jsonDecode(response.body, reviver: customDecode);
        API()
            .cache()
            .insertDocument(id, docId, returnedDocument["content"] ?? {});
        return Document(returnedDocument["exists"], docId, id,
            returnedDocument["content"] ?? {});
      } else {
        print("${response.statusCode.toString()}: ${response.body}");
        return API().cache().getDocument(id, docId);
      }
    });
  }

  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    Document doc = Document(true, docId, id, {});
    await doc.update(data);
  }

  Future<void> deleteDocument(String docId) async {
    Document doc = Document(true, docId, id, {});
    await doc.delete();
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
    if (_orderby != null)
      return "&orderBy=$_orderby&orderByOrder=$_orderByOrder";
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

  Future<List<Document>> get() async {
    await API().auth().isAuthenticated();

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
      response = await http
          .get(
            url,
            headers: getHeader(),
          )
          .timeout(Duration(seconds: 5));
    } catch (e) {}

    if (response == null) {
      var docs = await API().cache().searchForDocuments(id, query, _orderby,
          start: _start,
          end: _limit,
          orderUp: _orderByOrder != null ? _orderByOrder == 1 : true);
      return docs;
    }

    if (response.statusCode == 200) {
      var returnedDocuments = jsonDecode(response.body, reviver: customDecode);
      for (var doc in returnedDocuments) {
        documents.add(Document(true, doc["id"], id, doc["content"] ?? {}));
      }
    } else {
      print("${response.statusCode.toString()}: ${response.body}");
      var docs = await API().cache().searchForDocuments(id, query, _orderby,
          start: _start,
          end: _limit,
          orderUp: _orderByOrder != null ? _orderByOrder == 1 : true);

      return docs;
    }

    return documents;
  }

  Future<List<Document>> getMany(List<String> docs) {
    return Future(() async {
      await API().auth().isAuthenticated();

      List<Document> documents = [];

      Map<String, dynamic> docQuery = {};
      docQuery["docs"] = docs;

      var url = Uri.parse(API().connection().collectionGetMany() +
          "?" +
          "target=$id&docs=${jsonEncode(docQuery, toEncodable: customEncode)}");

      var response;
      try {
        response = await http.get(
          url,
          headers: getHeader(),
        );
      } catch (e) {}

      if (response == null) {
        return await API()
            .cache()
            .searchForDocuments(id, query, _orderby, start: _start, end: _limit)
            .timeout(Duration(seconds: 5));
      }

      if (response.statusCode == 200) {
        var returnedDocuments =
            jsonDecode(response.body, reviver: customDecode);
        for (var doc in returnedDocuments) {
          documents.add(Document(true, doc["id"], id, doc["content"] ?? {}));
        }
      } else {
        print("${response.statusCode.toString()}: ${response.body}");
      }

      return documents;
    });
  }

  Future<List<Document>> getComplex(Map<dynamic, dynamic> query) {
    return Future(() async {
      await API().auth().isAuthenticated();

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
        response = await http
            .get(
              url,
              headers: getHeader(),
            )
            .timeout(Duration(seconds: 5));
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
        print("${response.statusCode.toString()}: ${response.body}");
      }

      return documents;
    });
  }

  Future<Response> addImpl(
      String docID, Map<String, dynamic> data, int time) async {
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
      response = await http
          .post(url, body: decode, headers: getHeader())
          .timeout(Duration(seconds: 5));
    } catch (e) {
      print(e);
    }
    return response;
  }

  Future<Document> add(Map<String, dynamic> data, {String customId}) async {
    await API().auth().isAuthenticated();
    String docID =
        customId != null ? customId : mongo.ObjectId(clientMode: true).$oid;

    API().cache().insertDocument(id, docID, data);

    API().socket().beOptimistic(id, EUpdateType.Add, docID, data);

    API().cache().queueAdd(id, docID, data);

    return Document(true, docID, id, data);
  }
}

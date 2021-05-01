import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

class Collection {
  final String id;

  Collection(this.id);

  Map<String, dynamic> query = {};

  void where(Map<String, dynamic> addQuery) {
    query.addAll(addQuery);
  }

  Future<List<Document>> get() {
    return Future(() async {
      assert(API().auth().isAuthenticated());
      List<Document> documents = [];

      Map<String, dynamic> urlQuery = {
        "target": id,
        "query": json.encode(query)
      };

      var url = Uri.parse(
          API().connection().collectionGet() + mapToQueryString(urlQuery));

      var response = await http.get(url);

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
}

class Document {
  final bool exists;
  final dynamic data;
  final String id;

  Document(this.exists, this.id, this.data);
}

class Database {
  Collection collection(String id) {
    return new Collection(id);
  }
}

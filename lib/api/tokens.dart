import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class TokenData implements DocumentData {
  String? token;
  bool? read;
  bool? write;
  bool? delete;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData("title", token, payload);
    int permission = 0;
    if (read == true) permission |= 0x01;
    if (write == true) permission |= 0x02;
    if (delete == true) permission |= 0x04;

    insertData("permission", permission, payload);
    return payload;
  }

  @override
  constructFromJson(Map<String, dynamic> json) {
    token = readDataFromJson("token", json);
    int permission = readDataFromJson("permission", json);
    read = (permission & 0x01) != 0;
    write = (permission & 0x02) != 0;
    delete = (permission & 0x04) != 0;
  }
}

class Tokens extends Collection<TokenData> {
  @override
  String get type => "Tokens";

  @override
  Document<TokenData> add(DocumentData values) {
    return addSimpleDocument(type, "v1/token", values);
  }

  @override
  void delete(String documentId, Document originalDocument) {
    deleteSimpleDocument(type, "v1/token", documentId, originalDocument.dataObject);
  }

  @override
  Future<Document<TokenData>> get(String id) async {
    return getSimpleDocument(id, "v1/token/$id", type, (data) => TokenData()..constructFromJson(data.content), () => TokenData());
  }

  @override
  Future<List<Document<TokenData>>> getAll() async {
    var collection = await getCollection<TokenData>("v1/tokens", "");

    if (!collection.useOffline) {
      List<Document<TokenData>> tokens = collection.onlineData.map<Document<TokenData>>((e) => Document(e["exists"], e["id"], TokenData()..constructFromJson(e["content"]), type)).toList();
      API().cache().cacheListOfDocuments(tokens);
      return tokens;
    }

    return collection.offlineData;
  }

  @deprecated
  @override
  void update(String documentId, DocumentData values) {
    throw UnimplementedError();
  }
}

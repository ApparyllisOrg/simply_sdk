import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:http/http.dart' as http;

enum OperationType { add, update, delete }

class Operation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;

  Operation(this.id, this.type, this.data) {
    if (type != OperationType.delete) {
      assert(data != null);
    }
  }

  String _getType() {
    switch (type) {
      case OperationType.add:
        return "add";
      case OperationType.update:
        return "update";
      case OperationType.delete:
        return "delete";
    }
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "type": _getType(), "data": data};
  }
}

class Batch {
  final String collection;
  List<Operation> operations = [];

  Batch(this.collection) {
    assert(collection != null);
  }

  void add(String id, Map<String, dynamic> data) {
    operations.add(Operation(id, OperationType.add, data));
  }

  void update(String id, Map<String, dynamic> data) {
    operations.add(Operation(id, OperationType.update, data));
  }

  void delete(String id) {
    operations.add(Operation(id, OperationType.delete, {}));
  }

  void enqueueToCache() {
    for (Operation op in operations) {
      switch (op.type) {
        case OperationType.add:
          API().cache().queueAdd(collection, op.id, op.data);
          continue;
        case OperationType.update:
          API().cache().queueUpdate(collection, op.id, op.data);
          continue;
        case OperationType.delete:
          API().cache().queueDelete(collection, op.id);
          continue;
      }
    }
  }

  Future<void> commit() async {
    if (operations.isEmpty) {
      return;
    }

    var url = Uri.parse(API().connection().batch());

    List<Map<String, dynamic>> sendOps = [];

    for (Operation op in operations) {
      sendOps.add(op.toJson());
    }

    for (Operation op in operations) {
      switch (op.type) {
        case OperationType.add:
          API().cache().insertDocument(collection, op.id, op.data);
          continue;
        case OperationType.update:
          API().cache().updateDocument(collection, op.id, op.data);
          continue;
        case OperationType.delete:
          API().cache().removeDocument(collection, op.id);
          continue;
      }
    }

    var response;
    try {
      response = await http.post(url,
          headers: getHeader(),
          body: jsonEncode({
            "operations": sendOps,
            "target": collection,
            "updateTime": DateTime.now().millisecondsSinceEpoch
          }, toEncodable: customEncode));
    } catch (e) {}

    if (response == null) {
      enqueueToCache();
      return;
    }

    if (response.statusCode == 200) {
      // Happy!
    } else {
      if (response.statusCode != 400) {
        enqueueToCache();
      }
      print("${response.statusCode.toString()}: ${response.body}");
    }
  }
}

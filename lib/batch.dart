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

  void add(Map<String, dynamic> data) {
    operations.add(Operation("N/A", OperationType.add, data));
  }

  void update(String id, Map<String, dynamic> data) {
    operations.add(Operation(id, OperationType.update, data));
  }

  void delete(String id) {
    operations.add(Operation(id, OperationType.delete, {}));
  }

  Future<void> commit() async {
    var url = Uri.parse(API().connection().batch());

    List<Map<String, dynamic>> sendOps = [];

    for (Operation op in operations) {
      sendOps.add(op.toJson());
    }

    var response = await http.post(url,
        headers: getHeader(),
        body: jsonEncode({
          "operations": sendOps,
          "target": collection,
          "updateTime": DateTime.now().millisecondsSinceEpoch
        }));

    if (response.statusCode == 200) {
      // Happy!
    } else {
      throw ("${response.statusCode.toString()}: ${response.body}");
    }
  }
}

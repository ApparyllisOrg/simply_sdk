import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/modules/collection.dart';

typedef DocumentId = String;

class DocumentRef {
  final String type;
  final String id;

  DocumentRef(this.id, this.type);

  bool operator ==(other) {
    return other is DocumentRef && other.type == type && other.id == id;
  }

  int get hashCode {
    return (type + id).hashCode;
  }
}

class Document {
  final String id;
  final String type;
  final bool fromCache;
  final DocumentData dataObject;
  late Map<String, dynamic> data;

  bool exists;

  T value<T>(String field, T fallback) {
    var value = data[field];
    if (value != null) {
      // Special case where every DateTime needs to be converted to Timestamp, as
      // we only provide Timestamp to ensure server/cache works in harmony
      if (value is DateTime) {
        return Timestamp.fromDate(value) as T;
      }
      return value as T;
    }
    return fallback;
  }

  T getDataObject<T>() => dataObject as T;

  static Map<String, dynamic> convertTime(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (key.toLowerCase().contains("time") && value is int) {
        data[key] = Timestamp.fromMillisecondsSinceEpoch(value);
      }
    });
    return data;
  }

  Document(this.exists, this.id, this.dataObject, this.type,
      {this.fromCache = false}) {
    data = dataObject.toJson();
    data = convertTime(this.data);
  }
}

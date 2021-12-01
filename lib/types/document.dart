import 'package:cloud_firestore/cloud_firestore.dart';
class DocumentRef {
  final String collectionId;
  final String id;

  DocumentRef(this.id, this.collectionId);

  bool operator ==(other) {
    return other is DocumentRef &&
        other.collectionId == collectionId &&
        other.id == id;
  }

  int get hashCode {
    return (collectionId + id).hashCode;
  }
}

class Document {
  bool exists;
  final bool fromCache;
  Map<String, dynamic> data;
  final String collectionId;
  final String id;

  T value<T>(String field, T fallback) {
    // This really shouldn't be null, investigate.
    if (data == null) {
      return fallback;
    }

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

  static Map<String, dynamic> convertTime(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (key.toLowerCase().contains("time") && value is int) {
        data[key] = Timestamp.fromMillisecondsSinceEpoch(value);
      }
    });
    return data;
  }

  Document(this.exists, this.id, this.collectionId, this.data,
      {this.fromCache = false}) {
    assert(id != null);
    assert(collectionId != null);
    if (data == null) data = {};
    data = convertTime(this.data);
  }
}

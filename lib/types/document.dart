import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simply_sdk/modules/collection.dart';

typedef DocumentId = String;
typedef DocumentConstructor<Type> = Document<Type> Function(String, Map<String, dynamic>);

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

class Document<ObjectClass> {
  final String id;
  final String type;
  final bool fromCache;
  final ObjectClass dataObject;
  late Map<String, dynamic> data;

  bool exists;

  static Map<String, dynamic> convertTime(Map<String, dynamic> data) {
    return data;
  }

  Document(this.exists, this.id, this.dataObject, this.type,
      {this.fromCache = false}) {
    data = (dataObject as DocumentData).toJson();
    data = convertTime(this.data);
  }
}
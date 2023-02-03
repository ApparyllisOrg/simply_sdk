import 'package:simply_sdk/types/document.dart';

abstract class DocumentData {
  Map<String, dynamic> toJson();
  constructFromJson(Map<String, dynamic> json);
}

class EmptyDocumentData extends DocumentData {
  @override
  constructFromJson(Map<String, dynamic> json) {}

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}

enum EChangeType { Add, Update, Delete }

typedef DocumentChange<ObjectType extends DocumentData> = void Function(Document<ObjectType>, EChangeType);

abstract class Collection<ObjectType extends DocumentData> {
  String type = 'NONE';

  List<DocumentChange<ObjectType>?> boundChanges = [];

  Future<Document<DocumentData>> get(String id);
  Future<List<Document<DocumentData>>> getAll();
  Document<DocumentData> add(ObjectType values);
  void update(String documentId, ObjectType values);
  void delete(String documentId, Document originalDocument);

  void listenForChanges(DocumentChange<ObjectType> bindFunc) {
    boundChanges.add(bindFunc);
  }

  void cancelListenForChanges(DocumentChange<ObjectType> bindFunc) {
    boundChanges.remove(bindFunc);
  }

  void propogateChanges(Document<ObjectType> change, EChangeType changeType) {
    boundChanges.forEach((element) {
      if (element != null) element(change, changeType);
    });
  }
}

import 'package:simply_sdk/document.dart';

class DocumentSubscriptions {
  Map<DocumentRef, List<Function>> callbacks = {};

  void listenToDocument(DocumentRef ref, Function callback) {
    List<Function> functions = callbacks[ref] ?? [];
    functions.add(callback);
  }

  void stopListeningToDocument(DocumentRef ref, Function callback) {
    List<Function> functions = callbacks[ref] ?? [];
    functions.remove(callback);
  }

  void propogateChange(Document doc) {
    List<Function> functions =
        callbacks[DocumentRef(doc.id, doc.collectionId)] ?? [];
    functions.forEach((element) {
      if (element != null) {
        element(doc);
      }
    });
  }
}

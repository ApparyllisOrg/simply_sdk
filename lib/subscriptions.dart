import 'package:simply_sdk/document.dart';

class DocumentSubscriptions {
  Map<DocumentRef, List<Function>> _callbacks = {};

  void listenToDocument(DocumentRef ref, Function callback) {
    List<Function> functions = _callbacks[ref] ?? [];
    functions.add(callback);
    _callbacks[ref] = functions;
  }

  void stopListeningToDocument(DocumentRef ref, Function callback) {
    List<Function> functions = _callbacks[ref] ?? [];
    functions.remove(callback);
    _callbacks[ref] = functions;
  }

  void propogateChange(Document doc) {
    List<Function> functions =
        _callbacks[DocumentRef(doc.id, doc.collectionId)] ?? [];
    functions.forEach((element) {
      if (element != null) {
        element(doc);
      }
    });
  }
}

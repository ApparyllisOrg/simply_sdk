import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class EventListener {
  List<Function(String, Document<dynamic>, EChangeType)?> callbacks = [];

  void onEvent(String type, Document<dynamic> doc, EChangeType changeType) {
    callbacks.remove(null);
    callbacks.forEach((element) {
      if (element != null) {
        element(type, doc, changeType);
      }
    });
  }

  void registerCallback(Function(String, Document<dynamic>, EChangeType) callback) {
    callbacks.add(callback);
  }
}

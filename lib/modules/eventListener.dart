import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';

class EventListener {
  List<Function(String, Document<dynamic>, EChangeType, bool)?> callbacks = [];

  void onEvent(String type, Document<dynamic> doc, EChangeType changeType, bool bLocalEvent) {
    callbacks.remove(null);
    callbacks.forEach((element) {
      if (element != null) {
        element(type, doc, changeType, bLocalEvent);
      }
    });
  }

  void registerCallback(Function(String, Document<dynamic>, EChangeType, bool) callback) {
    callbacks.add(callback);
  }
}

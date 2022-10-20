import 'package:simply_sdk/modules/network.dart';
import 'package:simply_sdk/simply_sdk.dart';

class Event {
  void reportEvent(String event) {
    API().network().request(NetworkRequest(HttpRequestMethod.Post, "v1/event", DateTime.now().millisecondsSinceEpoch, payload: {"event": event}));
  }

  void reportOpen(String event) {
    API().network().request(NetworkRequest(HttpRequestMethod.Post, "v1/event/open", DateTime.now().millisecondsSinceEpoch));
  }
}

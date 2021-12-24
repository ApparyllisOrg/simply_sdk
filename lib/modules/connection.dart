import 'package:flutter/foundation.dart';

class Connection {
  static const String localHost = "http://localhost:8443";
  static const String prodHost = "https://api.apparyllis.com:8443";

  String currentHost = "";

  Connection() {
    if (kDebugMode) {
      currentHost = localHost;
    } else {
      currentHost = prodHost;
    }
  }

  String getRequestUrl(String path, String query) {
    String overrideIp = const String.fromEnvironment("ip");
    String useIp = overrideIp.isNotEmpty ? overrideIp : currentHost;
    return "$useIp/$path?$query";
  }

  void setDebugMode(bool debug) {
    if (debug)
      currentHost = localHost;
    else
      currentHost = prodHost;
  }

  void setCurrentHost(String host) {
    assert(host.isNotEmpty);
    currentHost = host;
  }

  String configGet() => "$currentHost/config/conf.json";
}

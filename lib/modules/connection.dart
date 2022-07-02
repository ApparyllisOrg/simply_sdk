import 'package:flutter/foundation.dart';

class Connection {
  static const String localHost = "http://localhost:8443";
  static const String prodHost = "https://v2.apparyllis.com";

  String _currentHost = "";

  String getCurrentHost() {
    String overrideIp = const String.fromEnvironment("IP");
    return overrideIp.isNotEmpty ? overrideIp : _currentHost;
  }

  Connection() {
    if (kDebugMode) {
      _currentHost = localHost;
    } else {
      _currentHost = prodHost;
    }
  }

  String getRequestUrl(String path, String query) {
    String overrideIp = const String.fromEnvironment("IP");
    String useIp = overrideIp.isNotEmpty ? overrideIp : _currentHost;
    return "$useIp/$path?$query";
  }

  void setDebugMode(bool debug) {
    if (debug)
      _currentHost = localHost;
    else
      _currentHost = prodHost;
  }

  void setCurrentHost(String host) {
    assert(host.isNotEmpty);
    _currentHost = host;
  }

  String configGet() => "https://dist.apparyllis.com/config/conf.json";
}

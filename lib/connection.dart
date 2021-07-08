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

  void setDebugMode(bool debug) {
    if (debug)
      currentHost = localHost;
    else
      currentHost = prodHost;
  }

  void setCurrentHost(String host) {
    assert(host != null);
    assert(host.isNotEmpty);
    currentHost = host;
  }

  String collectionGet() => "$currentHost/collection/get";
  String collectionGetMany() => "$currentHost/collection/getMany";
  String collectionGetComplex() => "$currentHost/collection/getComplex";
  String documentGet() => "$currentHost/document/get";
  String documentAdd() => "$currentHost/document/add";
  String documentUpdate() => "$currentHost/document/update";
  String documentDelete() => "$currentHost/document/delete";
  String batch() => "$currentHost/collection/batch";
}

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../simply_sdk.dart';

http.Response generateFailedResponse(Exception e) {
  if (e is HttpException)
    API().debug().logFine("ERROR: " + e.uri.toString() + " => " + e.message);
  if (e is SocketException)
    API()
        .debug()
        .logFine("ERROR: " + e.address.toString() + " => " + e.message);
  if (e is TimeoutException)
    API().debug().logFine("ERROR: Timeout: " +
        e.duration.toString() +
        " => " +
        (e.message ?? ""));
  return http.Response("", 503);
}

class SimplyHttpClient extends http.BaseClient {
  static SimplyHttpClient? _instance;

  SimplyHttpClient._() {}

  factory SimplyHttpClient() {
    if (_instance == null) {
      _instance = new SimplyHttpClient._();
    }
    return _instance!;
  }

  http.Client _httpClient = new http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    API().debug().logFine("HTTP => ${request.method} => ${request.url}");
    request.headers.addAll({
      "Authorization": API().auth().getToken() ?? "",
      "content-type": "application/json; charset=UTF-8"
    });
    return _httpClient.send(request);
  }
}

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../simply_sdk.dart';

List<String> nonLoggableRequests = ["/v1/event", "/v1/event/open"];

http.Response generateFailedResponse(Exception e) {
  if (e is HttpException) API().debug().logFine("ERROR: " + e.uri.toString() + " => " + e.message);
  if (e is SocketException) API().debug().logFine("ERROR: " + e.address.toString() + " => " + e.message);
  if (e is TimeoutException) API().debug().logFine("ERROR: Timeout: " + e.duration.toString() + " => " + (e.message ?? ""));
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
    if (nonLoggableRequests.indexWhere((element) => request.url.path.endsWith(element)) < 0) {
      API().debug().logFine("HTTP => ${request.method} => ${request.url}");
    }

    request.headers.addAll({"content-type": "application/json; charset=UTF-8"});

    if (!request.headers.containsKey("Authorization")) {
      request.headers.addAll({"Authorization": API().auth().getToken() ?? ""});
    }

    return _httpClient.send(request);
  }
}

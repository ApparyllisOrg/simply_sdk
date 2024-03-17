import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../simply_sdk.dart';

List<String> nonLoggableRequests = ['/v1/event', '/v1/event/open'];

http.Response generateFailedResponse(Exception e) {
  if (e is HttpException) API().debug().logFine('ERROR: ${e.uri} => ${e.message}');
  if (e is SocketException) API().debug().logFine('ERROR: ${e.address} => ${e.message}');
  if (e is TimeoutException) API().debug().logFine('ERROR: Timeout: ${e.duration} => ${e.message ?? ''}');
  return http.Response('', 503);
}

class SimplyHttpClient extends http.BaseClient {
  factory SimplyHttpClient() {
    if (_instance == null) {
      _instance = new SimplyHttpClient._();
    }
    return _instance!;
  }

  SimplyHttpClient._() {}
  static SimplyHttpClient? _instance;

  final http.Client _httpClient = new http.Client();

  double getSecondsSinceLastResponse() {
    return (DateTime.now().millisecondsSinceEpoch * .001) - (_lastResponse * .001);
  }

  int _lastResponse = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (nonLoggableRequests.indexWhere((element) => request.url.path.endsWith(element)) < 0) {
      API().debug().logFine('HTTP => ${request.method} => ${request.url}');
    }

    request.headers.addAll({'accept-encoding': 'gzip'});
    request.headers.addAll({'connection': 'keep-alive'});
    request.headers.addAll({'content-type': 'application/json; charset=UTF-8'});

    if (!request.headers.containsKey('Authorization')) {
      request.headers.addAll({'Authorization': API().auth().getToken() ?? ''});
    }

    return _httpClient.send(request).then((http.StreamedResponse resoponse) {
      _lastResponse = DateTime.now().millisecondsSinceEpoch;
      return resoponse;
    });
  }
}

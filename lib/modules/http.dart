import 'package:http/http.dart' as http;
import '../simply_sdk.dart';

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
    request.headers.addAll({"Authorization": API().auth().getToken() ?? "", "content-type": "application/json; charset=UTF-8", "accept-encoding": "gzip"});
    return _httpClient.send(request);
  }
}

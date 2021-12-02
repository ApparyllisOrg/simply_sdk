import 'package:http/http.dart' as http;
import '../simply_sdk.dart';

class SimplyHttpClient extends http.BaseClient{
  static SimplyHttpClient _singleton = SimplyHttpClient();

  factory SimplyHttpClient() {
    return _singleton;
  }

  http.Client _httpClient = new http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll({
      "Authorization": API().auth().getToken() ?? "",
      "content-type" : "application/json",
      "accept-encoding" : "gzip"
      }
    );
    return _httpClient.send(request);
  }
}
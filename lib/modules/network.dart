import 'dart:async';

import 'dart:math';

import 'package:http/http.dart' as http;

import '../simply_sdk.dart';

enum HttpRequestMethod
{
  Post,
  Patch,
  Delete
}

class NetworkRequest {
  final HttpRequestMethod method;
  final String path;
  final String? query;
  final Map<String, dynamic>? payload;
  final int timestamp;
  final Function? onDone;

  NetworkRequest(this.method, this.path, this.timestamp,
      {this.query, this.payload, this.onDone});
}

// TODO: Save pending network requests
class Network {
  Network() {
    tick();
  }

  List<NetworkRequest> _pendingRequests = [];

  void tick() async {
    try {
      List<Future> requestsToSend = [];
      for (int i = 0; i < min(2, _pendingRequests.length); i++) {
        NetworkRequest request = _pendingRequests[i];

        requestsToSend.add(Future(() async {
          String url = API()
              .connection()
              .getRequestUrl(request.path, request.query ?? "");

          Uri uri = Uri.parse(url);

          http.Response? response;

          try {
            switch (request.method) {
              case HttpRequestMethod.Delete:
                {
                  response = await http.delete(uri,
                      headers: {"Operation-Time": request.timestamp.toString()},
                      body: request.payload);
                  break;
                }
              case HttpRequestMethod.Patch:
                {
                  response = await http.patch(uri,
                      headers: {"Operation-Time": request.timestamp.toString()},
                      body: request.payload);
                  break;
                }
              case HttpRequestMethod.Post:
                {
                  response = await http.post(uri,
                      headers: {"Operation-Time": request.timestamp.toString()},
                      body: request.payload);
                  break;
                }
              default:
                {
                  API().reportError("Attempting to send an unsupported method",
                      StackTrace.current);
                  _pendingRequests.remove(request);
                  break;
                }
            }

            if (response?.statusCode == 200) {
              _pendingRequests.remove(request);
              request.onDone!();
            }
          } catch (e) {}
        }));
      }
      await Future.wait(requestsToSend);
      await Future.delayed(Duration(milliseconds: 300));
      tick();
    } catch (e) {
      API().reportError(e, StackTrace.current);
      await Future.delayed(Duration(milliseconds: 300));
      tick();
    }
  }

  void request(NetworkRequest request) {
    _pendingRequests.add(request);
  }
}
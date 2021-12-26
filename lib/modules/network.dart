import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:simply_sdk/modules/http.dart';

import '../simply_sdk.dart';

enum HttpRequestMethod { Post, Patch, Delete, Get }

List<int> acceptedResponseCodes = [0, 200, 400, 409, 404, 500, 501, 502, 503, 504, 403, 401, 406, 405, 204];

class NetworkRequest {
  final HttpRequestMethod method;
  final String path;
  final String? query;
  final Map<String, dynamic>? payload;
  final int timestamp;
  final Function? onDone;

  NetworkRequest(this.method, this.path, this.timestamp, {this.query, this.payload, this.onDone});
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
          String url = API().connection().getRequestUrl(request.path, request.query ?? "");

          Uri uri = Uri.parse(url);

          http.Response? response;

          try {
            switch (request.method) {
              case HttpRequestMethod.Delete:
                {
                  response = await SimplyHttpClient().delete(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload)).catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              case HttpRequestMethod.Patch:
                {
                  response = await SimplyHttpClient().patch(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload)).catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              case HttpRequestMethod.Post:
                {
                  response = await SimplyHttpClient().post(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload)).catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              default:
                {
                  API().reportError("Attempting to send an unsupported method", StackTrace.current);
                  _pendingRequests.remove(request);
                  break;
                }
            }

            int responseCode = response?.statusCode ?? 0;
            if (acceptedResponseCodes.contains(responseCode)) {
              _pendingRequests.remove(request);
              if (request.onDone != null) request.onDone!();
            } else {
              print(response?.body);
            }
          } catch (e) {
            print(e);
          }
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

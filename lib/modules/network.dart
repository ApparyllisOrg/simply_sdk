import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:simply_sdk/modules/http.dart';

import '../simply_sdk.dart';

enum HttpRequestMethod { Post, Patch, Delete, Get }

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
                  response = await SimplyHttpClient().delete(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload));
                  break;
                }
              case HttpRequestMethod.Patch:
                {
                  response = await SimplyHttpClient().patch(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload));
                  break;
                }
              case HttpRequestMethod.Post:
                {
                  response = await SimplyHttpClient().post(uri, headers: {"Operation-Time": request.timestamp.toString()}, body: jsonEncode(request.payload));
                  break;
                }
              default:
                {
                  API().reportError("Attempting to send an unsupported method", StackTrace.current);
                  _pendingRequests.remove(request);
                  break;
                }
            }

            if (response?.statusCode == 200) {
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

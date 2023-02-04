import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:simply_sdk/helpers.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/modules/http.dart';

import '../simply_sdk.dart';

enum HttpRequestMethod { Post, Patch, Delete, Get }

List<int> acceptedResponseCodes = [0, 200, 409, 500, 501, 403, 404, 406, 405, 204, 400];
List<int> ignoreResponseCodes = [502, 503, 504];

class NetworkRequest {

  NetworkRequest(this.method, this.path, this.timestamp, {this.query, this.payload, this.onDone});
  final HttpRequestMethod method;
  final String path;
  final String? query;
  final Map<String, dynamic>? payload;
  final int timestamp;
  final Function? onDone;

  String toJson() {
    Map<String, dynamic> data = {};
    data['method'] = method.index;
    data['path'] = path;
    data['query'] = query ?? '';
    data['payload'] = payload ?? {};
    data['timestamp'] = timestamp;

    return jsonEncode(data);
  }

  static NetworkRequest fromJson(Map<String, dynamic> data) {
    return NetworkRequest(HttpRequestMethod.values[data['method']], data['path'], data['timestamp'], payload: data['payload'], query: data['query']);
  }
}

class Network {
  Network() {}

  bool initialized = false;
  List<NetworkRequest> _pendingRequests = [];
  int numFailedTicks = 0;

  int getNumPendingRequests() => _pendingRequests.length;
  int getNumFailedTicks() => numFailedTicks;

  Future<void> initialize() async {
    await loadPendingNetworkRequests();
    tick();
  }

  void invalidateRequests() {
    _pendingRequests = [];
  }

  List<String> getJsonPendingRequestsFromString(String data) {
    List<dynamic> savedRequestsRaw = jsonDecode(data, reviver: customDecode) as List<dynamic>;
    return savedRequestsRaw.cast<String>();
  }

  void loadPendingRequestsFromJson(List<String> jsonList) {
    _pendingRequests = [];
    _pendingRequests = jsonList.map((e) => NetworkRequest.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Timer? saveTimer;
  bool dirty = false;
  void markDirty() {
    dirty = true;
    if (saveTimer?.isActive == true) saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 10), saveFromTimer);
  }

  void saveFromTimer() {
    if (!initialized) {
      markDirty();
      return;
    }

    if (!dirty) {
      return;
    }

    save();
  }

  Future<void> save() async {
    if (!initialized) {
      markDirty();
      return;
    }

    dirty = false;

    try {
      List<String> convertedData = [];
      _pendingRequests.forEach((element) {
        convertedData.add(element.toJson());
      });

      if (kIsWeb) {
        html.window.localStorage['pendingRequests'] = jsonEncode(convertedData);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        final dbPath = '${dir.path}/pendingRequests.db';
        File file = File(dbPath);
        file.writeAsStringSync(jsonEncode(convertedData));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadPendingNetworkRequests() async {
    if (kIsWeb) {
      bool syncExists = html.window.localStorage.containsKey('pendingRequests');
      List<String> savedRequestsCasted = syncExists ? getJsonPendingRequestsFromString(html.window.localStorage['pendingRequests'] ?? '') : [];
      loadPendingRequestsFromJson(savedRequestsCasted);
      print('Loaded pending requests');
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        final dbPath = '${dir.path}/pendingRequests.db';

        File file = File(dbPath);
        bool exists = await file.exists();

        if (exists) {
          String jsonObjectString = await file.readAsString();
          if (jsonObjectString.isNotEmpty) {
            loadPendingRequestsFromJson(getJsonPendingRequestsFromString(jsonObjectString));
          } else {
            _pendingRequests = [];
          }
        } else {
          _pendingRequests = [];
        }

        initialized = true;
        print('Loaded pending requests');
      } catch (e) {
        API().reportError(e, StackTrace.current);
        print(e);
        _pendingRequests = [];
      }
    }
  }

  Future<void> rescheduleNextTick(bool success) async {
    await save();

    // If no pending requests succeeded, delay the attempts
    if (!success) {
      numFailedTicks++;

      // Limit to 30s delay between attempts
      numFailedTicks = min(30, numFailedTicks);

      await Future.delayed(Duration(milliseconds: 1000 * numFailedTicks));
    } else {
      numFailedTicks = 0;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    tick();
  }

  Future<void> tick() async {
    try {
      List<Future> requestsToSend = [];
      int numPendingRequests = _pendingRequests.length;
      for (int i = 0; i < min(1, _pendingRequests.length) && API().auth().canSendHttpRequests(); i++) {
        NetworkRequest request = _pendingRequests[i];

        requestsToSend.add(Future(() async {
          String url = API().connection().getRequestUrl(request.path, request.query ?? '');

          Uri uri = Uri.parse(url);

          http.Response? response;

          try {
            switch (request.method) {
              case HttpRequestMethod.Delete:
                {
                  response = await SimplyHttpClient()
                      .delete(uri, headers: {'Operation-Time': request.timestamp.toString()}).catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              case HttpRequestMethod.Patch:
                {
                  response = await SimplyHttpClient()
                      .patch(uri, headers: {'Operation-Time': request.timestamp.toString()}, body: jsonEncode(request.payload ?? '{}'))
                      .catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              case HttpRequestMethod.Post:
                {
                  response = await SimplyHttpClient()
                      .post(uri, headers: {'Operation-Time': request.timestamp.toString()}, body: jsonEncode(request.payload ?? '{}'))
                      .catchError(((e) => generateFailedResponse(e)));
                  break;
                }
              default:
                {
                  API().reportError('Attempting to send an unsupported method', StackTrace.current);
                  _pendingRequests.remove(request);
                  break;
                }
            }

            int responseCode = response?.statusCode ?? 0;

            if (responseCode == 401) {
              if (API().auth().isAuthenticated()) {
                await API().auth().refreshToken(null);
              }
            }

            String error = "[$responseCode] during ${request.method} => ${request.path}. Response is ${response?.body ?? ""}";

            if (acceptedResponseCodes.contains(responseCode)) {
              if (responseCode != 200) {
                API().debug().logError(error);
              }
              _pendingRequests.remove(request);

              if (request.onDone != null) {
                request.onDone!();
              }
            } else {
              if (!ignoreResponseCodes.contains(responseCode)) {
                API().debug().logError(error);
              }
              print(response?.body);
            }
          } catch (e) {
            print(e);
          }
        }));
      }
      await Future.wait(requestsToSend);
      rescheduleNextTick(numPendingRequests != _pendingRequests.length || _pendingRequests.isEmpty);
    } catch (e) {
      API().reportError(e, StackTrace.current);
      rescheduleNextTick(false);
    }
  }

  void request(NetworkRequest request) {
    _pendingRequests.add(request);
    markDirty();
  }
}

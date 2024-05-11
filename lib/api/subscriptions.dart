import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:simply_sdk/types/request.dart';

class SubscriptionData implements DocumentData {
  String? currency;
  int? periodEnd;
  int? periodStart;
  int? subscriptionStart;
  int? price;
  bool? cancelled;
  String? priceId;

  @override
  constructFromJson(Map<String, dynamic> json) {
    currency = readDataFromJson('currency', json);
    periodEnd = readDataFromJson('periodEnd', json);
    periodStart = readDataFromJson('periodStart', json);
    subscriptionStart = readDataFromJson('subscriptionStart', json);
    price = readDataFromJson('price', json);
    cancelled = readDataFromJson('cancelled', json);
    priceId = readDataFromJson('priceId', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('currency', currency, payload);
    insertData('periodEnd', periodEnd, payload);
    insertData('periodStart', periodStart, payload);
    insertData('subscriptionStart', subscriptionStart, payload);
    insertData('price', price, payload);
    insertData('cancelled', cancelled, payload);
    insertData('priceId', priceId, payload);

    return payload;
  }
}

class CheckoutResult {
  bool bSuccess = false;
  String error = "";
  String url = "";
  String id = "";

  constructFromJson(Map<String, dynamic> json) {
    url = readDataFromJson('url', json);
    id = readDataFromJson('id', json);
  }
}

class Subscriptions {
  Future<CheckoutResult> createCheckoutSessions(String price) async {
    final Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/subscription/create', '')),
            body: jsonEncode({'price': price}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final CheckoutResult session = CheckoutResult()..constructFromJson(json);
      session.bSuccess = true;
      return session;
    }

    final CheckoutResult result = CheckoutResult();
    result.bSuccess = false;
    result.error = response.body;

    return result;
  }

  Future<RequestResponse> changeSubscription(String price) async {
    final Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/subscription/change', '')),
            body: jsonEncode({'price': price}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    return RequestResponse(response.statusCode == 200, response.body);
  }

  Future<RequestResponse> refundSubscription(
      String feedback, String? comment) async {
    Map<String, String> body = {};
    body["feedback"] = feedback;
    if (comment != null) {
      body["comment"] = comment;
    }

    final Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/subscription/refund', '')),
            body: jsonEncode(body))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    return RequestResponse(response.statusCode == 200, response.body);
  }

  Future<RequestResponse> cancelSubscription(
      String feedback, String? comment) async {
    Map<String, String> body = {};
    body["feedback"] = feedback;
    if (comment != null) {
      body["comment"] = comment;
    }

    final Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
              API().connection().getRequestUrl('v1/subscription/cancel', ''),
            ),
            body: jsonEncode(body))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    return RequestResponse(response.statusCode == 200, response.body);
  }

  Future<RequestResponse> reactivateSubscription() async {
    final Response response = await SimplyHttpClient()
        .post(Uri.parse(
            API().connection().getRequestUrl('v1/subscription/reactivate', '')))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    return RequestResponse(response.statusCode == 200, response.body);
  }

  Future<Document<SubscriptionData>?> getActiveSubscription() async {
    final Response response = await SimplyHttpClient()
        .get(Uri.parse(
            API().connection().getRequestUrl('v1/subscription/get', '')))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      final DocumentResponse docResponse = DocumentResponse.fromString(response.body);
      final SubscriptionData data = SubscriptionData()
        ..constructFromJson(docResponse.content);
      return Document(true, docResponse.id, data, "subscriptions");
    }
    return null;
  }

  Future<RequestResponse> getManagementPage() async {
    final Response response = await SimplyHttpClient()
        .get(
          Uri.parse(API()
              .connection()
              .getRequestUrl('v1/subscription/management', '')),
        )
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    return RequestResponse(response.statusCode == 200, response.body);
  }
}

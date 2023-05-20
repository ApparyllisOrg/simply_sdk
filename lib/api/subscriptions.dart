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
  int? price;
  bool? cancelled;

  @override
  constructFromJson(Map<String, dynamic> json) {
    currency = readDataFromJson('currency', json);
    periodEnd = readDataFromJson('periodEnd', json);
    price = readDataFromJson('price', json);
    cancelled = readDataFromJson('cancelled', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};

    insertData('currency', currency, payload);
    insertData('periodEnd', periodEnd, payload);
    insertData('price', price, payload);
    insertData('cancelled', cancelled, payload);

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
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/subscription/create', '')),
            body: jsonEncode({'price': price}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      CheckoutResult session = CheckoutResult()..constructFromJson(json);
      session.bSuccess = true;
      return session;
    }

    CheckoutResult result = CheckoutResult();
    result.bSuccess = false;
    result.error = response.body;

    return result;
  }

  Future<RequestResponse> cancelSubscription() async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(
            API().connection().getRequestUrl('v1/subscription/cancel', '')))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return RequestResponse(true, response.body);
    }

    return RequestResponse(false, response.body);
  }

  Future<RequestResponse> reactivateSubscription() async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(
            API().connection().getRequestUrl('v1/subscription/reactivate', '')))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return RequestResponse(true, response.body);
    }

    return RequestResponse(false, response.body);
  }

  Future<Document<SubscriptionData>?> getActiveSubscription() async {
    Response response = await SimplyHttpClient()
        .get(Uri.parse(
            API().connection().getRequestUrl('v1/subscription/get', '')))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      DocumentResponse docResponse = DocumentResponse.fromString(response.body);
      SubscriptionData data = SubscriptionData()
        ..constructFromJson(docResponse.content);
      return Document(true, docResponse.id, data, "subscriptions");
    }
    return null;
  }
}

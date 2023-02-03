import 'dart:convert';

import 'package:http/http.dart';

class RequestResponse {

  RequestResponse(this.success, this.message);
  final bool success;
  final String message;
}

RequestResponse createResponseObject(Response response) {
  try {
    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return RequestResponse(true, jsonResponse['msg'] ?? '');
    } else {
      return RequestResponse(false, jsonResponse['msg'] ?? '');
    }
  } catch (e) {
    if (response.statusCode == 200) {
      return RequestResponse(true, response.body);
    } else {
      return RequestResponse(false, response.body);
    }
  }
}

RequestResponse createFailResponseObject() => RequestResponse(false, 'Something went wrong. Try again later.');

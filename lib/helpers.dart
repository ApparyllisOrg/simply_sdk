import 'package:simply_sdk/simply_sdk.dart';

getHeader() => {
      "Content-Type": "application/json",
      "Authorization": API().auth().getToken()
    };

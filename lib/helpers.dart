import 'package:simply_sdk/simply_sdk.dart';

import 'auth.dart';

getHeader() => {
      "Content-Type": "application/json",
      "Authorization": API().auth().getToken()
    };

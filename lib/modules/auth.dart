import 'dart:convert';

import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';

class AuthCredentials {
  final String? _lastToken;
  final String? _lastRefreshToken;
  final String? _lastUid;

  AuthCredentials(this._lastToken, this._lastRefreshToken, this._lastUid);

  bool isAuthed() {
    return _lastUid != null && _lastToken != null && _lastRefreshToken != null;
  }
}

class Auth {
  AuthCredentials credentials = AuthCredentials(null, null, null);

  List<Function(AuthCredentials)?> onAuthChange = [];

  Future<bool> initializeOffline() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    checkJwtValidity();

    if ((pref.containsKey("access_key") && pref.containsKey("refresh_key"))) {
      String accessKey = pref.getString("access_key")!;
      String refreshKey = pref.getString("refresh_key")!;
      Map<String, dynamic> jwtPayload = Jwt.parseJwt(accessKey);
      credentials = AuthCredentials(accessKey, refreshKey, jwtPayload["sub"]);
      return credentials.isAuthed();
    }

    return false;
  }

  Future<bool> initialize(String? fallbackToken) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    checkJwtValidity();

    if ((pref.containsKey("access_key") && pref.containsKey("refresh_key"))) {
      String accessKey = pref.getString("access_key")!;
      String refreshKey = pref.getString("refresh_key")!;

      Map<String, dynamic> jwtPayload = Jwt.parseJwt(accessKey);

      credentials = AuthCredentials(accessKey, refreshKey, jwtPayload["sub"]);

      String? result = await refreshToken(null, bNotify: false);

      if (result == null) {
        return true;
      }

      // Unable to refresh your session, refresh token is no longer valid
      return false;
    }

    if (fallbackToken != null) {
      String? result = await refreshToken(fallbackToken, bNotify: false);

      if (result == null) {
        return true;
      }

      // Unable to refresh your session, refresh token is no longer valid
      return false;
    }

    return false;
  }

  void _notifyAuthChange() {
    onAuthChange.forEach((element) {
      if (element != null) {
        element(credentials);
      }
    });
  }

  void checkJwtValidity() async {
    if (credentials.isAuthed()) {
      try {
        Map<String, dynamic> jwtPayload = Jwt.parseJwt(credentials._lastToken ?? "");
        DateTime expiry = DateTime.fromMillisecondsSinceEpoch(jwtPayload["exp"] * 1000);
        if (expiry.difference(DateTime.now()).inMinutes < 5) {
          API().debug().logFine("JWT about to expire, refreshing token");
          refreshToken(null);
        }
      } catch (e) {}
    }

    await Future.delayed(Duration(seconds: 5));
    checkJwtValidity();
  }

  void _getAuthDetailsFromResponse(String response) async {
    Map<String, dynamic> content = jsonDecode(response) as Map<String, dynamic>;
    Map<String, dynamic> jwtPayload = Jwt.parseJwt(content["access"]);

    String _lastToken = content["access"];
    String _lastRefreshToken = content["refresh"];
    String _lastUid = jwtPayload["sub"];

    bool previousAuthed = credentials.isAuthed();

    credentials = AuthCredentials(_lastToken, _lastRefreshToken, _lastUid);

    if (credentials.isAuthed() != previousAuthed) {
      _notifyAuthChange();
    }

    SharedPreferences pref = await SharedPreferences.getInstance();

    if (credentials.isAuthed()) {
      pref.setString("access_key", _lastToken);
      pref.setString("refresh_key", _lastRefreshToken);
    } else {
      pref.remove("access_key");
      pref.remove("refresh_key");
    }
  }

  void _invalidateAuth({bool bNotify = true}) {
    bool previousAuthed = credentials.isAuthed();

    credentials = AuthCredentials(null, null, null);

    if (credentials.isAuthed() != previousAuthed && bNotify) {
      _notifyAuthChange();
    }
  }

  Future<String?> registerEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/register", "")), body: jsonEncode({"email": email, "password": password}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));
    ;
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    if (response.statusCode == 400) {
      return "Unknown user or password";
    } else {
      return response.body;
    }
  }

  Future<String?> loginEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/login", "")), body: jsonEncode({"email": email, "password": password}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));
    ;
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    if (response.statusCode == 400) {
      return "Unknown user or password";
    } else {
      return response.body;
    }
  }

  void logout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove("access_key");
    pref.remove("refresh_key");

    _invalidateAuth();
  }

  Future<String?> loginGoogle(String credential) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/login/oauth/google", "")), body: jsonEncode({"credential": credential}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> loginApple(String credential) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/login/oauth/apple", "")), body: jsonEncode({"credential": credential}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> changeEmail(String currentEmail, String newEmail, String password) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/email/change", "")),
            body: jsonEncode({"oldEmail": currentEmail, "password": password, "newEmail": newEmail}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    if (response.statusCode == 400) {
      return "Invalid password or email";
    } else {
      return response.body;
    }
  }

  Future<String?> requestResetPassword(String email) async {
    Response response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl("v1/auth/password/reset", "email=$email")))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  Future<String?> requestVerify() async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl("v1/auth/verification/request", "")))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  Future<String?> refreshToken(String? forceRefreshToken, {bool bNotify = true}) async {
    if (!credentials.isAuthed()) {
      return "Not authenticated";
    }

    Response response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl("v1/auth/refresh", "")),
            headers: {"Authorization": forceRefreshToken ?? (credentials._lastRefreshToken ?? "")})
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    if (response.statusCode == 401) {
      _invalidateAuth(bNotify: bNotify);
    }

    return response.body;
  }

  Future<String?> remoteCheckIsRefreshTokenValid(String? forceRefreshToken) async {
    Response response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("v1/auth/refresh/valid", "")),
        headers: {"Authorization": forceRefreshToken ?? (credentials._lastRefreshToken ?? "")}).catchError(((e) => generateFailedResponse(e)));

    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  String? getToken() => credentials._lastToken;
  String? getUid() => credentials._lastUid;
  bool isAuthenticated() {
    return credentials.isAuthed();
  }

  bool isVerified() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload = Jwt.parseJwt(credentials._lastToken ?? "");
      return jwtPayload["verified"] != false;
    }
    return true;
  }

  String getEmail() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload = Jwt.parseJwt(credentials._lastToken ?? "");
      return jwtPayload["email"]!;
    }
    return "";
  }
}

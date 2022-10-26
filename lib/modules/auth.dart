import 'dart:convert';

import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
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

  Future<bool> initialize(String? fallbackToken) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    if ((pref.containsKey("access_key") && pref.containsKey("refresh_key"))) {
      String accessKey = pref.getString("access_key")!;
      String refreshKey = pref.getString("refresh_key")!;

      Map<String, dynamic> jwtPayload = Jwt.parseJwt(accessKey);

      credentials = AuthCredentials(accessKey, refreshKey, jwtPayload["uid"]);

      String? result = await refreshToken(null);

      // Unable to refresh your session, refresh token is no longer valid
      if (result == null) {
        return false;
      }

      return true;
    }

    if (fallbackToken != null) {
      String? result = await refreshToken(fallbackToken);

      // Unable to refresh your session, refresh token is no longer valid
      if (result == null) {
        return false;
      }

      return true;
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

  void _getAuthDetailsFromResponse(String response) async {
    Map<String, dynamic> content = jsonDecode(response) as Map<String, dynamic>;
    Map<String, dynamic> jwtPayload = Jwt.parseJwt(content["access"]);

    String _lastToken = content["access"];
    String _lastRefreshToken = content["refresh"];
    String _lastUid = jwtPayload["uid"];

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

  void _invalidateAuth() {
    bool previousAuthed = credentials.isAuthed();

    credentials = AuthCredentials(null, null, null);

    if (credentials.isAuthed() != previousAuthed) {
      _notifyAuthChange();
    }
  }

  Future<String?> registerEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl("v1/auth/register", "")), body: jsonEncode({"email": email, "password": password})).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> loginEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl("v1/auth/login", "")), body: jsonEncode({"email": email, "password": password})).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> registerGoogle(String credential) async {
    Response response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl("v1/auth/register/oauth/google", "")), body: jsonEncode({"credential": credential})).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> loginGoogle(String credential) async {
    Response response = await SimplyHttpClient().post(Uri.parse(API().connection().getRequestUrl("v1/auth/login/oauth/google", "")), body: jsonEncode({"credential": credential})).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> refreshToken(String? forceRefreshToken) async {
    Response response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("v1/auth/refresh", "")), headers: {"Authorization": forceRefreshToken ?? (credentials._lastRefreshToken ?? "")}).catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> remoteCheckIsRefreshTokenValid(String? forceRefreshToken) async {
    Response response = await SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl("v1/auth/refresh/valid", "")), headers: {"Authorization": forceRefreshToken ?? (credentials._lastRefreshToken ?? "")}).catchError(((e) => generateFailedResponse(e)));

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
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';

import 'collection.dart';

class AuthLog implements DocumentData {
  int? at;
  String? ip;
  String? action;

  @override
  void constructFromJson(Map<String, dynamic> json) {
    at = readDataFromJson('at', json);
    ip = readDataFromJson('ip', json);
    action = readDataFromJson('action', json);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {};
    return payload;
  }
}

class AuthCredentials {
  AuthCredentials(this._lastToken, this._lastRefreshToken, this._lastUid);
  final String? _lastToken;
  final String? _lastRefreshToken;
  final String? _lastUid;

  bool isAuthed() {
    return _lastUid != null && _lastToken != null && _lastRefreshToken != null;
  }
}

class Auth {
  AuthCredentials credentials = AuthCredentials(null, null, null);
  Timer? _tokenRefreshTimer;

  List<Function(AuthCredentials)?> onAuthChange = [];
  bool bIsRefreshingToken = false;
  bool bInitialized = false;

  Future<bool> initializeOffline() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    API().debug().logInfo('Initializing auth offline');

    resumeTokenRefreshing();

    if ((pref.containsKey('access_key') && pref.containsKey('refresh_key'))) {
      API().debug().logInfo('Initializing auth from cache');

      String accessKey = pref.getString('access_key')!;
      String refreshKey = pref.getString('refresh_key')!;
      Map<String, dynamic> jwtPayload = Jwt.parseJwt(accessKey);
      credentials = AuthCredentials(accessKey, refreshKey, jwtPayload['sub']);
      return credentials.isAuthed();
    }

    return false;
  }

  Future<bool> initialize(String? fallbackToken) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    API().debug().logInfo('Initializing auth online');

    resumeTokenRefreshing();

    if ((pref.containsKey('access_key') && pref.containsKey('refresh_key'))) {
      API().debug().logInfo('Initializing auth from cache');

      String accessKey = pref.getString('access_key')!;
      String refreshKey = pref.getString('refresh_key')!;

      Map<String, dynamic> jwtPayload = Jwt.parseJwt(accessKey);

      credentials = AuthCredentials(accessKey, refreshKey, jwtPayload['sub']);

      String? result = await refreshToken(null, bNotify: false);

      bInitialized = true;

      if (result == null) {
        return true;
      }

      // Unable to refresh your session, refresh token is no longer valid
      return false;
    }

    if (fallbackToken != null) {
      String? result = await refreshToken(fallbackToken, bNotify: false);

      bInitialized = true;

      if (result == null) {
        return true;
      }

      // Unable to refresh your session, refresh token is no longer valid
      return false;
    }

    bInitialized = true;

    return false;
  }

  void _notifyAuthChange() {
    onAuthChange.forEach((element) {
      if (element != null) {
        element(credentials);
      }
    });
  }

  Future<void> checkJwtValidity(Timer? timer) async {
    if (credentials.isAuthed()) {
      try {
        Map<String, dynamic> jwtPayload =
            Jwt.parseJwt(credentials._lastToken ?? '');
        DateTime expiry =
            DateTime.fromMillisecondsSinceEpoch(jwtPayload['exp'] * 1000);
        if (expiry.difference(DateTime.now()).inMinutes < 5) {
          API().debug().logFine('JWT about to expire, refreshing token');
          refreshToken(null);
        }
      } catch (e) {}
    }
  }

  Future<void> _getAuthDetailsFromResponse(String response) async {
    Map<String, dynamic> content = jsonDecode(response) as Map<String, dynamic>;
    Map<String, dynamic> jwtPayload = Jwt.parseJwt(content['access']);

    String _lastToken = content['access'];
    String _lastRefreshToken = content['refresh'];
    String _lastUid = jwtPayload['sub'];

    bool previousAuthed = credentials.isAuthed();

    credentials = AuthCredentials(_lastToken, _lastRefreshToken, _lastUid);

    if (credentials.isAuthed() != previousAuthed) {
      _notifyAuthChange();
    }

    SharedPreferences pref = await SharedPreferences.getInstance();

    if (credentials.isAuthed()) {
      pref.setString('access_key', _lastToken);
      pref.setString('refresh_key', _lastRefreshToken);
    } else {
      pref.remove('access_key');
      pref.remove('refresh_key');
    }
  }

  void _invalidateAuth({bool bNotify = true}) {
    String stack = StackTrace.current.toString();

    API()
        .debug()
        .logInfo('Invalidating auth with following callstack: ${stack}');

    bool previousAuthed = credentials.isAuthed();

    credentials = AuthCredentials(null, null, null);

    if (credentials.isAuthed() != previousAuthed && bNotify) {
      _notifyAuthChange();
    }
  }

  Future<String?> registerEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(API().connection().getRequestUrl('v1/auth/register', '')),
            body: jsonEncode({'email': email, 'password': password}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));
    ;
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    if (response.statusCode == 400) {
      return response.body;
    } else {
      return response.body;
    }
  }

  Future<String?> loginEmailPassword(String email, String password) async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API().connection().getRequestUrl('v1/auth/login', '')),
            body: jsonEncode({'email': email, 'password': password}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));
    ;
    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    if (response.statusCode == 400) {
      return 'Unknown user or password';
    } else {
      return response.body;
    }
  }

  Future<void> logout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove('access_key');
    pref.remove('refresh_key');

    _invalidateAuth();
  }

  Future<String?> loginGoogle(String credential) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(API()
                .connection()
                .getRequestUrl('v1/auth/login/oauth/google', '')),
            body: jsonEncode({'credential': credential}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> loginApple(String credential) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(API()
                .connection()
                .getRequestUrl('v1/auth/login/oauth/apple', '')),
            body: jsonEncode({'credential': credential}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    _invalidateAuth();

    return response.body;
  }

  Future<String?> changeEmail(
      String currentEmail, String newEmail, String password) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/auth/email/change', '')),
            body: jsonEncode({
              'oldEmail': currentEmail,
              'password': password,
              'newEmail': newEmail
            }))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    if (response.statusCode == 400) {
      return 'Invalid password or email';
    } else {
      return response.body;
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(API()
                .connection()
                .getRequestUrl('v1/auth/password/change', '')),
            body: jsonEncode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
              'uid': credentials._lastUid
            }))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      return null;
    }

    return response.body;
  }

  Future<String?> requestResetPassword(String email) async {
    Response response = await SimplyHttpClient()
        .get(Uri.parse(API()
            .connection()
            .getRequestUrl('v1/auth/password/reset', 'email=$email')))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  Future<String?> requestVerify() async {
    Response response = await SimplyHttpClient()
        .post(Uri.parse(API()
            .connection()
            .getRequestUrl('v1/auth/verification/request', '')))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  Future<String?> forgotEmail(String username) async {
    Response response = await SimplyHttpClient()
        .post(
            Uri.parse(
                API().connection().getRequestUrl('v1/auth/forgotemail', '')),
            body: jsonEncode({'username': username}))
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return response.body;
    }

    return response.body;
  }

  Future<String?> refreshToken(String? forceRefreshToken,
      {bool bNotify = true}) async {
    if (!credentials.isAuthed()) {
      return 'Not authenticated';
    }

    if (bIsRefreshingToken) return 'Already refreshing';

    bIsRefreshingToken = true;

    Response response = await SimplyHttpClient()
        .get(Uri.parse(API().connection().getRequestUrl('v1/auth/refresh', '')),
            headers: {
              'Authorization':
                  forceRefreshToken ?? (credentials._lastRefreshToken ?? '')
            })
        .catchError(((e) => generateFailedResponse(e)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      _getAuthDetailsFromResponse(response.body);
      bIsRefreshingToken = false;
      return null;
    }

    bIsRefreshingToken = false;

    if (response.statusCode == 401) {
      _invalidateAuth(bNotify: bNotify);
    }

    return response.body;
  }

  Future<String?> remoteCheckIsRefreshTokenValid(
      String? forceRefreshToken) async {
    Response response = await SimplyHttpClient().get(
        Uri.parse(
            API().connection().getRequestUrl('v1/auth/refresh/valid', '')),
        headers: {
          'Authorization':
              forceRefreshToken ?? (credentials._lastRefreshToken ?? '')
        }).catchError(((e) => generateFailedResponse(e)));

    if (response.statusCode == 200) {
      return null;
    }

    return response.body;
  }

  Future<void> waitForAbilityToSendRequests() async {
    Completer completer = Completer();

    if (canSendHttpRequests()) {
      completer.complete();
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      return waitForAbilityToSendRequests();
    }

    return completer.future;
  }

  void suspendTokenRefreshing(bool writeToLog) {
    if (_tokenRefreshTimer != null) {
      _tokenRefreshTimer!.cancel();
      _tokenRefreshTimer = null;
    }

    if (writeToLog) {
      API().debug().logFine('Suspending token refresh');
    }
  }

  void resumeTokenRefreshing() {
    suspendTokenRefreshing(false);
    checkJwtValidity(null);
    _tokenRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), checkJwtValidity);
    API().debug().logFine('Resuming token refresh');
  }

  String? getToken() => credentials._lastToken;
  String? getUid() => credentials._lastUid;
  bool isAuthenticated() {
    return credentials.isAuthed();
  }

  bool canSendHttpRequests() {
    return credentials.isAuthed() && bIsRefreshingToken == false;
  }

  bool isVerified() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload =
          Jwt.parseJwt(credentials._lastToken ?? '');
      return jwtPayload['verified'] != false;
    }
    return true;
  }

  bool isSubscriber() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload =
          Jwt.parseJwt(credentials._lastToken ?? '');
      return jwtPayload['subscriber'] == true;
    }
    return false;
  }

  bool isPatron() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload =
          Jwt.parseJwt(credentials._lastToken ?? '');
      return jwtPayload['patron'] == true;
    }
    return false;
  }

  bool isOauth2() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload =
          Jwt.parseJwt(credentials._lastToken ?? '');
      return jwtPayload['oAuth2'] == true;
    }
    return true;
  }

  String getEmail() {
    if (isAuthenticated()) {
      Map<String, dynamic> jwtPayload =
          Jwt.parseJwt(credentials._lastToken ?? '');
      return jwtPayload['email']!;
    }
    return '';
  }
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simply_sdk/simply_sdk.dart';

String _configSync = "lastConfigSync";
String _remoteConfig = "remoteConfig";

class RemoteConfig {
  Map<String, dynamic> _currentConfig = Map<String, dynamic>();
  SharedPreferences _sharedPrefs;

  RemoteConfig() {
    _initialize();
  }

  void _initialize() async {
    _sharedPrefs = await SharedPreferences.getInstance();
    if (_sharedPrefs.containsKey(_configSync)) {
      Timestamp lastSync = Timestamp.fromMillisecondsSinceEpoch(
          _sharedPrefs.getInt(_configSync));
      Timestamp now = Timestamp.now();

      int diff = now.compareTo(lastSync);

      // Check every 12 hours
      if (diff > 1000 * 60 * 60 * 12) {
        fetchConfig();
      } else {
        _loadConfig();
      }
    } else {
      fetchConfig();
    }
  }

  void fetchConfig() async {
    Timestamp now = Timestamp.now();

    _loadConfig();

    Uri url = Uri.parse(API().connection().configGet());
    Response response;
    try {
      response = await get(url);
      _sharedPrefs.setInt(_configSync, now.millisecondsSinceEpoch);
      _sharedPrefs.setString(_remoteConfig, response.body);
    } catch (e) {
      print(e);
    }

    _loadConfig();
  }

  void _loadConfig() {
    if (_sharedPrefs.containsKey(_remoteConfig)) {
      _currentConfig = jsonDecode(_sharedPrefs.getString(_remoteConfig))
          as Map<String, dynamic>;
    } else {
      _currentConfig = Map<String, dynamic>();
    }
  }

  Map<String, dynamic> getConfig() => _currentConfig;
}

import 'dart:convert';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simply_sdk/simply_sdk.dart';

String _configSync = 'lastConfigSync';
String _remoteConfig = 'remoteConfig';

class RemoteConfig {

  RemoteConfig() {
    _initialize();
  }
  Map<String, dynamic> _currentConfig = Map<String, dynamic>();
  late SharedPreferences _sharedPrefs;

  Future<void> _initialize() async {
    _sharedPrefs = await SharedPreferences.getInstance();
    if (_sharedPrefs.containsKey(_configSync)) {
      int lastSync = _sharedPrefs.getInt(_configSync) ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch;

      int diff = now - lastSync;

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

  Future<void> fetchConfig() async {
    int now = DateTime.now().millisecondsSinceEpoch;

    _loadConfig();

    Uri url = Uri.parse(API().connection().configGet());
    Response response;
    try {
      response = await get(url);
      _sharedPrefs.setInt(_configSync, now);
      _sharedPrefs.setString(_remoteConfig, response.body);
      API().debug().logInfo('Loaded remote config');
    } catch (e) {
      API().debug().logError('Failed to load remote config: ${e.toString()}');
      print(e);
    }

    _loadConfig();
  }

  void _loadConfig() {
    if (_sharedPrefs.containsKey(_remoteConfig) && _sharedPrefs.getString(_remoteConfig)!.isNotEmpty) {
      _currentConfig = jsonDecode(_sharedPrefs.getString(_remoteConfig)!) as Map<String, dynamic>;
    } else {
      _currentConfig = Map<String, dynamic>();
    }
  }

  Map<String, dynamic> getConfig() => _currentConfig;
}

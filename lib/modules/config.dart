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
      final int lastSync = _sharedPrefs.getInt(_configSync) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;

      final int diff = now - lastSync;

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
    final int now = DateTime.now().millisecondsSinceEpoch;

    _loadConfig();

    final Uri url = Uri.parse(API().connection().configGet());
    Response response;
    try {
      response = await get(url);

      _sharedPrefs.setInt(_configSync, now);

      if (response.statusCode == 200) {
        _sharedPrefs.setString(_remoteConfig, response.body);
      }
      API().debug().logInfo('Loaded remote config');
    } catch (e) {
      API().debug().logError('Failed to load remote config: ${e.toString()}');
      print(e);
    }

    _loadConfig();
  }

  void _loadConfig() {
    if (_sharedPrefs.containsKey(_remoteConfig) && _sharedPrefs.getString(_remoteConfig)!.isNotEmpty) {
      try {
        // If we previously got a non-200 status result it would corrupt the config cache, this will prevent that from persisting and prevents users having to wipe cache
        _currentConfig = jsonDecode(_sharedPrefs.getString(_remoteConfig)!) as Map<String, dynamic>;
      } catch (e) {
        _currentConfig = Map<String, dynamic>();
      }
    } else {
      _currentConfig = Map<String, dynamic>();
    }
  }

  Map<String, dynamic> getConfig() => _currentConfig;
}

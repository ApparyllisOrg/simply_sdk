import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
import "package:universal_html/html.dart" as html;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';

import '../simply_sdk.dart';

class Cache {
  Map<String, dynamic> _cache = Map<String, dynamic>();
  List<dynamic> _sync = [];

  void removeFromCache(String type, String id, {bool triggerUpdateSubscription: true}) {
    if (_cache[type] != null) {
      _cache[type].remove(id);
    }
    markDirty();
  }

  void updateToCache(String type, String id, Map<String, dynamic> _data) {
    Map<String, dynamic>? coll = _cache[type];
    if (coll != null) {
      if (coll.containsKey(id)) {
        Map<String, dynamic> dat = _cache[type][id];
        dat.addAll(_data);
        _cache[type][id] = dat;
      } else {
        _cache[type][id] = _data;
      }
    } else {
      _cache[type] = Map<String, dynamic>();
      _cache[type][id] = _data;
    }

    markDirty();
  }

  Map<String, dynamic>? getItemFromType(String type, String id) {
    Map<String, dynamic>? data = _cache[type] as Map<String, dynamic>?;
    if (data != null) {
      Map<String, dynamic>? docData = data[id] as Map<String, dynamic>?;
      if (docData != null) {
        docData.remove("id");
        return docData;
      }
    }
    return null;
  }

  Map<String, dynamic> getTypeCache(String type) {
    if (_cache.containsKey(type)) {
      Map<String, dynamic> data = _cache[type];
      return data;
    }
    return Map<String, dynamic>();
  }

  List<dynamic> getSyncQueue() {
    return _sync;
  }

  void clearTypeCache(String type) {
    _cache.remove(type);
    markDirty();
  }

  bool hasDataInCacheForType(String type) {
    return _cache.containsKey(type) && (_cache[type] as Map<String, dynamic>).length > 0;
  }

  Future<void> clear() {
    return Future(() async {
      try {
        _cache.clear();
        _sync.clear();
        markDirty();
      } catch (e) {
        API().reportError(e, StackTrace.current);
      }
    });
  }

  Timer? saveTimer;
  void markDirty() {
    dirty = true;
    if (saveTimer?.isActive == true) saveTimer?.cancel();
    saveTimer = Timer(Duration(milliseconds: 10), save);
  }

  bool dirty = false;
  Future<void> save() async {
    // Never-ever save if we haven't even loaded the cached data yet, we don't want to override
    // our cached data...
    if (!dirty || !isInitialzed) {
      return;
    }

    if (kIsWeb) {
      try {
        dirty = false;
        // Save cache
        html.window.localStorage["db"] = jsonEncode(_cache, toEncodable: customEncode);

        // Save sync
        html.window.localStorage["sync"] = jsonEncode(_sync, toEncodable: customEncode);

        Logger.root.fine("Saved sync and cache");
      } catch (e) {
        dirty = true;
        API().reportError(e, StackTrace.current);
        print(e);
      }
    } else {
      try {
        dirty = false;

        var dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        var dbPath = dir.path + "/simply.db";
        var syncPath = dir.path + "/simply_sync.db";

        // Save cache
        File file = File(dbPath);
        file.writeAsStringSync(jsonEncode(_cache, toEncodable: customEncode));

        // Save sync
        File syncFile = File(syncPath);
        syncFile.writeAsStringSync(jsonEncode(_sync, toEncodable: customEncode));

        print("Saved sync and cache");
      } catch (e) {
        dirty = true;
        API().reportError(e, StackTrace.current);
        print(e);
      }
    }
  }

  String lastInitializeFor = "";
  bool isInitialzed = false;
  Future<void> initialize(String initializeFor) async {
    if (lastInitializeFor != initializeFor) {
      lastInitializeFor = initializeFor;
    } else {
      return;
    }

    await Future(() async {
      if (kIsWeb) {
        bool syncExists = html.window.localStorage.containsKey("sync");
        bool dbExists = html.window.localStorage.containsKey("db");

        _sync = syncExists ? jsonDecode(html.window.localStorage["sync"] ?? "", reviver: customDecode) as List<dynamic> : [];

        _cache = dbExists ? jsonDecode(html.window.localStorage["db"] ?? "", reviver: customDecode) as Map<String, dynamic> : Map<String, dynamic>();
      } else {
        try {
          var dir = await getApplicationDocumentsDirectory();
          await dir.create(recursive: true);
          var dbPath = dir.path + "/simply.db";
          var syncPath = dir.path + "/simply_sync.db";

          File file = File(dbPath);
          bool exists = await file.exists();

          if (exists) {
            String jsonObjectString = await file.readAsString();
            if (jsonObjectString.isNotEmpty) {
              _cache = ((jsonDecode(jsonObjectString, reviver: customDecode)) ?? Map<String, dynamic>()) as Map<String, dynamic>;
            }
          } else {
            _cache = Map<String, dynamic>();
          }

          File syncFile = File(syncPath);
          bool syncExists = await syncFile.exists();

          if (syncExists) {
            String jsonObjectString = await syncFile.readAsString();
            _sync = jsonDecode(jsonObjectString, reviver: customDecode) as List<dynamic>;
          } else {
            _sync = [];
          }
        } catch (e) {
          API().reportError(e, StackTrace.current);
          print(e);
          _cache = Map<String, dynamic>();
          _sync = [];
        }
      }

      await Future.delayed(Duration(seconds: 1));
      isInitialzed = true;
      save();
    });
  }

  int getTime(var data) {
    return data;
  }

  String insertDocument(String type, String id, Map<String, dynamic> data, {bool doTriggerUpdateSubscription: true}) {
    Map<String, dynamic> dataCopy = Map.from(data);
    dataCopy["type"] = type;
    dataCopy["id"] = id;
    updateToCache(type, id, dataCopy);
    return id;
  }

  void updateDocument(String type, String id, Map<String, dynamic> data, {bool doTriggerUpdateSubscription: true}) async {
    Map<String, dynamic> dataCopy = Map.from(data);
    updateToCache(type, id, dataCopy);
  }

  Future<void> removeDocument(String type, String id, {bool doTriggerUpdateSubscription: true}) async {
    removeFromCache(type, id, triggerUpdateSubscription: doTriggerUpdateSubscription);
  }

  Map<String, dynamic>? getDocument(String type, String id) {
    try {
      Map<String, dynamic> docData = getItemFromType(type, id) ?? {};

      if (docData.isEmpty) {
        return null;
      }

      Map<String, dynamic> sendData = Map<String, dynamic>();
      docData.forEach((key, value) {
        if (key != "id" && key != "type") {
          sendData[key] = value;
        }
      });

      return docData;
    } catch (e) {
      print(e);
    }

    return null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
import "package:universal_html/html.dart" as html;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as fir;
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
    if (triggerUpdateSubscription) API().socket().updateSubscription(type);

    markDirty();
  }

  void updateToCache(String type, String id, Map<String, dynamic> _data, {bool triggerUpdateSubscription: true}) {
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

    if (triggerUpdateSubscription) API().socket().updateSubscription(type);
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
    if (data is fir.Timestamp) {
      return data.millisecondsSinceEpoch;
    }
    if (data is DateTime) {
      return data.millisecondsSinceEpoch;
    }
    if (data is int) {
      return data;
    }
    API().reportError("data in getTime is not int or timestamp!" + data.toString(), StackTrace.current);
    return 0;
  }

  String insertDocument(String type, String id, Map<String, dynamic> data, {bool doTriggerUpdateSubscription: true}) {
    Map<String, dynamic> dataCopy = Map.from(data);
    dataCopy["type"] = type;
    dataCopy["id"] = id;
    updateToCache(type, id, dataCopy, triggerUpdateSubscription: doTriggerUpdateSubscription);
    return id;
  }

  void updateDocument(String type, String id, Map<String, dynamic> data, {bool doTriggerUpdateSubscription: true}) async {
    Map<String, dynamic> dataCopy = Map.from(data);
    updateToCache(type, id, dataCopy, triggerUpdateSubscription: doTriggerUpdateSubscription);
  }

  Future<void> removeDocument(String type, String id, {bool doTriggerUpdateSubscription: true}) async {
    removeFromCache(type, id, triggerUpdateSubscription: doTriggerUpdateSubscription);
  }

  Document? getDocument(String type, String id) {
    try {
      Map<String, dynamic> docData;

      try {
        docData = getItemFromType(type, id) ?? {};
        if (docData.isEmpty) {
          return null;
        }

        Map<String, dynamic> sendData = Map<String, dynamic>();
        docData.forEach((key, value) {
          if (key != "id" && key != "type") {
            sendData[key] = value;
          }
        });

        DocumentData? docDataObject = convertJsonToDataObject(docData, type);
        if (docDataObject != null) {
          return Document(true, id, docDataObject, type, fromCache: true);
        } else {
          API().reportError("Unable to convert cached document data to a document data object. Attempt to convert type: $type", StackTrace.current);
        }
        return null;
      } catch (e) {
        print(e);
      }
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }

    return null;
  }
  /*
  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries, String orderBy,
      {int start, int end, bool orderUp = true}) async {
    List<Document> docs = [];

    try {
      Map<String, dynamic> cachedCollection = getCollectionCache(collection);

      cachedCollection.forEach((key, value) {
        if (queries.isEmpty) {
          docs.add(Document(true, key, collection, value));
        } else {
          bool isSatisfied = true;
          queries.forEach((queryKey, queryValue) {
            if (value.containsKey(queryKey)) {
              if (!queryValue.isSatisfied(value[queryKey])) {
                isSatisfied = false;
              }
            }
          });
          if (isSatisfied)
            docs.add(Document(true, key, collection, value, fromCache: true));
        }
      });

      if (orderBy != null) {
        docs.sort((Document a, Document b) => orderUp
            ? a.value(orderBy, 0) >= b.value(orderBy, 0)
                ? 1
                : -1
            : a.value(orderBy, 0) >= b.value(orderBy, 0)
                ? -1
                : 1);
      }

      if (end != null) {
        if (start == null) start = 0;
        List<Document> returnDocs = [];
        for (int i = start; i < end && i < docs.length; i++) {
          returnDocs.add(docs[i]);
        }
        return returnDocs;
      }
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }

    return docs;
  }
  */
}

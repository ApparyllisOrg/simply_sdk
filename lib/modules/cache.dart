import 'dart:async';
import 'dart:convert';
import 'package:simply_sdk/types/document.dart';
import "package:universal_html/html.dart" as html;
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/socket.dart';

import '../simply_sdk.dart';

class Cache {
  Map<String, dynamic> _cache = Map<String, dynamic>();
  List<dynamic> _sync = [];

  void removeFromCache(String collection, String id,
      {bool triggerUpdateSubscription: true}) {
    if (_cache[collection] != null) {
      _cache[collection].remove(id);
    }
    if (triggerUpdateSubscription)
      API().socket().updateSubscription(collection);

    markDirty();
  }

  void updateToCache(String collection, String id, Map<String, dynamic> _data,
      {bool triggerUpdateSubscription: true}) {
    if (_data == null) return;

    Map<String, dynamic> coll = _cache[collection];
    if (_cache[collection] != null) {
      if (coll.containsKey(id)) {
        Map<String, dynamic> dat = _cache[collection][id];
        dat?.addAll(_data);
        _cache[collection][id] = dat;
      } else {
        _cache[collection][id] = _data;
      }
    } else {
      _cache[collection] = Map<String, dynamic>();
      _cache[collection][id] = _data;
    }

    markDirty();

    if (triggerUpdateSubscription)
      API().socket().updateSubscription(collection);
  }

  Map<String, dynamic> getItemFromCollection(String collection, String id) {
    Map<String, dynamic> data = _cache[collection] as Map<String, dynamic>;
    if (data != null) {
      Map<String, dynamic> docData = data[id] as Map<String, dynamic>;
      if (docData != null) {
        docData.remove("id");
        return docData;
      }
    }
    return null;
  }

  Map<String, dynamic> getCollectionCache(String collection) {
    if (_cache.containsKey(collection)) {
      Map<String, dynamic> data = _cache[collection];
      if (data != null) {
        return data;
      }
    }
    return Map<String, dynamic>();
  }

  List<dynamic> getSyncQueue() {
    return _sync;
  }

  void clearCollectionCache(String collection) {
    _cache.remove(collection);
    markDirty();
  }

  bool hasDataInCacheForCollection(String collection) {
    return _cache.containsKey(collection) &&
        (_cache[collection] as Map<String, dynamic>).length > 0;
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

  Timer saveTimer;
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
        html.window.localStorage["db"] =
            jsonEncode(_cache, toEncodable: customEncode);

        // Save sync
        html.window.localStorage["sync"] =
            jsonEncode(_sync, toEncodable: customEncode);

        print("Saved sync and cache");
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
        syncFile
            .writeAsStringSync(jsonEncode(_sync, toEncodable: customEncode));

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

        _sync = syncExists
            ? jsonDecode(html.window.localStorage["sync"],
                reviver: customDecode) as List<dynamic>
            : [];

        _cache = dbExists
            ? jsonDecode(html.window.localStorage["db"], reviver: customDecode)
                as Map<String, dynamic>
            : Map<String, dynamic>();
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
            _cache = jsonDecode(jsonObjectString, reviver: customDecode)
                as Map<String, dynamic>;
          } else {
            _cache = Map<String, dynamic>();
          }

          File syncFile = File(syncPath);
          bool syncEists = await syncFile.exists();

          if (syncEists) {
            String jsonObjectString = await syncFile.readAsString();
            _sync = jsonDecode(jsonObjectString, reviver: customDecode)
                as List<dynamic>;
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
    if (!bSyncing) trySyncToServer();
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
    API().reportError(
        "data in getTime is not int or timestamp!" + data.toString(),
        StackTrace.current);
    return 0;
  }

  Timer syncTimer;
  void markSyncDirty() {
    if (syncTimer?.isActive == true) syncTimer?.cancel();
    syncTimer = Timer(Duration(milliseconds: 10), trySyncToServer);
  }

  bool bSyncing = false;
  void trySyncToServer() async {
    try {
      if (bSyncing) {
        markSyncDirty();
        return;
      }

      bSyncing = true;

      try {
        List<Future> serverCommands = [];
        for (int i = 0; i < min(2, _sync.length); i++) {
          var data = _sync[i];
          // Todo: Tick the network
        }
        await Future.wait(serverCommands);
      } catch (e) {
        print(e);
      }
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }

    await Future.delayed(Duration(milliseconds: 500));
    print("End sync");

    bSyncing = false;

    if (_sync.isNotEmpty) {
      markSyncDirty();
    }
  }

  void enqueueSync(Map<String, dynamic> data) {
    _sync.add(data);
    markDirty();
    markSyncDirty();
  }

  void queueDelete(String collection, String id) {
    try {
      enqueueSync({
        "queue": true,
        "id": id,
        "collectionRef": collection,
        "action": "delete",
        "time": DateTime.now().millisecondsSinceEpoch
      });
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  void queueUpdate(String collection, String id, Map<String, dynamic> data) {
    try {
      enqueueSync({
        "queue": true,
        "id": id,
        "collectionRef": collection,
        "action": "update",
        "data": data,
        "time": DateTime.now().millisecondsSinceEpoch
      });
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  void queueDeleteField(String collection, String field) {
    try {
      enqueueSync({
        "queue": true,
        "collectionRef": collection,
        "action": "deleteField",
        "field": field,
        "time": DateTime.now().millisecondsSinceEpoch
      });
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  void queueAdd(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    try {
      enqueueSync({
        "queue": true,
        "id": id,
        "collectionRef": collection,
        "action": "add",
        "data": data,
        "time": DateTime.now().millisecondsSinceEpoch
      });
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  String insertDocument(String collection, String id, Map<String, dynamic> data,
      {bool doTriggerUpdateSubscription: true}) {
    try {
      Map<String, dynamic> dataCopy = Map.from(data);
      dataCopy["collection"] = collection;
      dataCopy["id"] = id;
      updateToCache(collection, id, dataCopy,
          triggerUpdateSubscription: doTriggerUpdateSubscription);
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }

    return id;
  }

  void updateDocument(String collection, String id, Map<String, dynamic> data,
      {bool doTriggerUpdateSubscription: true}) async {
    try {
      Map<String, dynamic> dataCopy = Map.from(data);
      updateToCache(collection, id, dataCopy,
          triggerUpdateSubscription: doTriggerUpdateSubscription);
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  Future<void> removeDocument(String collection, String id,
      {bool doTriggerUpdateSubscription: true}) async {
    try {
      removeFromCache(collection, id,
          triggerUpdateSubscription: doTriggerUpdateSubscription);
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }
  }

  Document getDocument(String collection, String id) {
    Document doc = Document(false, id, collection, {}, fromCache: true);

    try {
      Map<String, dynamic> docData;

      try {
        docData = getItemFromCollection(collection, id);
      } catch (e) {
        print(e);
      }

      if (docData == null || docData.isEmpty) {
        return doc;
      }

      Map<String, dynamic> sendData = Map<String, dynamic>();
      docData.forEach((key, value) {
        if (key != "id" && key != "collection") {
          sendData[key] = value;
        }
      });
      doc.data = sendData;
      doc.exists = true;
    } catch (e) {
      API().reportError(e, StackTrace.current);
    }

    return doc;
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

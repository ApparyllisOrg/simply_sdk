import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/socket.dart';

import 'collection.dart';
import 'document.dart';
import 'simply_sdk.dart';

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
  }

  void updateToCache(String collection, String id, Map<String, dynamic> _data,
      {bool triggerUpdateSubscription: true}) {
    if (_data == null) return;

    Map<String, dynamic> coll = _cache[collection];
    if (_cache[collection] != null) {
      if (coll.containsKey(id)) {
        Map<String, dynamic> dat = _cache[collection][id];
        dat.addAll(_data);
        _cache[collection][id] = dat;
      } else {
        _cache[collection][id] = _data;
      }
    } else {
      _cache[collection] = Map<String, dynamic>();
      _cache[collection][id] = _data;
    }

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

  void clearCollectionCache(String collection) {
    _cache.remove(collection);
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
        await save();
      } catch (e) {
        API().reportError(e);
      }
    });
  }

  Future<void> save() async {
    try {
      var dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      var dbPath = dir.path + "/simply.db";
      var syncPath = dir.path + "/simply_sync.db";

      // Save cache
      File file = File(dbPath);
      await file.writeAsString(jsonEncode(_cache, toEncodable: customEncode));

      // Save sync
      File syncFile = File(syncPath);
      await syncFile
          .writeAsString(jsonEncode(_sync, toEncodable: customEncode));
    } catch (e) {
      API().reportError(e);
      print(e);
    }
    await Future.delayed(Duration(seconds: 1));
    save();
  }

  String lastInitializeFor = "";
  Future<void> initialize(String initializeFor) async {
    if (lastInitializeFor != initializeFor) {
      lastInitializeFor = initializeFor;
      clear();
    } else {
      return;
    }

    await Future(() async {
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
        API().reportError(e);
        print(e);
        _cache = Map<String, dynamic>();
        _sync = [];
      }

      await Future.delayed(Duration(seconds: 1));
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
        "data in getTime is not int or timestamp!" + data.toString());
    return 0;
  }

  void removeFromQueue(String collection, Map<String, dynamic> item) async {
    try {
      removeFromCache(collection, item["id"]);
    } catch (e) {
      API().reportError(e);
    }
  }

  bool bSyncing = false;
  void trySyncToServer() async {
    bSyncing = true;
    await Future.delayed(Duration(seconds: 3));
    try {
      if (_sync == null || _sync.isEmpty) {
        trySyncToServer();
        return;
      }

      try {
        List<Future> serverCommands = [];
        for (int i = 0; i < min(2, _sync.length); i++) {
          var data = _sync[i];
          switch (data["action"]) {
            case "delete":
              var future = Future(() async {
                var doc = await API()
                    .database()
                    .collection(data["collectionRef"])
                    .document(data["id"],
                        addToCache: false, forceFromCache: true);
                var response;
                try {
                  response = await doc.deleteImpl(getTime(data["time"]));
                } catch (e) {}
                if (response != null) {
                  if (response.statusCode == 400 ||
                      response.statusCode == 200) {
                    print("sent ${data["id"]} to cloud");
                    _sync.remove(data);
                  }
                }
              });
              serverCommands.add(future);

              break;
            case "update":
              var future = Future(() async {
                var doc = await API()
                    .database()
                    .collection(data["collectionRef"])
                    .document(data["id"],
                        addToCache: false, forceFromCache: true);
                var response;
                try {
                  Map<String, dynamic> sendData = data["data"];
                  sendData.remove("uid");
                  response =
                      await doc.updateImpl(sendData, getTime(data["time"]));
                } catch (e) {}
                if (response != null) {
                  if (response.statusCode == 400 ||
                      response.statusCode == 200) {
                    print("sent ${data["id"]} to cloud");
                    _sync.remove(data);
                  }
                }
              });
              serverCommands.add(future);
              break;
            case "add":
              var future = Future(() async {
                var response;
                try {
                  Map<String, dynamic> sendData = data["data"];
                  sendData.remove("uid");
                  response = await API()
                      .database()
                      .collection(data["collectionRef"])
                      .addImpl(data["id"], sendData, getTime(data["time"]));
                } catch (e) {}

                if (response != null) {
                  if (response.statusCode == 400 ||
                      response.statusCode == 200) {
                    print("sent ${data["id"]} to cloud");
                    _sync.remove(data);
                  }
                }
              });
              serverCommands.add(future);
              break;
          }
        }
        await Future.wait(serverCommands);
      } catch (e) {
        print(e);
      }
    } catch (e) {
      API().reportError(e);
    }

    await Future.delayed(Duration(milliseconds: 100));
    trySyncToServer();
  }

  void enqueueSync(Map<String, dynamic> data) {
    _sync.add(data);
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
      API().reportError(e);
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
      API().reportError(e);
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
      API().reportError(e);
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
      API().reportError(e);
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
      API().reportError(e);
    }
  }

  Future<void> removeDocument(String collection, String id,
      {bool doTriggerUpdateSubscription: true}) async {
    try {
      removeFromCache(collection, id,
          triggerUpdateSubscription: doTriggerUpdateSubscription);
    } catch (e) {
      API().reportError(e);
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
      API().reportError(e);
    }

    return doc;
  }

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
      API().reportError(e);
    }

    return docs;
  }
}

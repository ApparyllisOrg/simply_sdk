import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/socket.dart';

import 'collection.dart';
import 'document.dart';
import 'simply_sdk.dart';

class Cache {
  Map<String, Map<String, Map<String, dynamic>>> _cache =
      Map<String, Map<String, Map<String, dynamic>>>();

  void removeFromCache(String collection, String id) {
    Map<String, Map<String, dynamic>> data = _cache[collection];
    if (data != null) {
      data.remove(id);
    }
  }

  void updateToCache(String collection, String id, Map<String, dynamic> _data) {
    Map<String, Map<String, dynamic>> data = _cache[collection];

    if (_data == null) return;

    if (data != null) {
      data[id] = _data;
    } else {
      _cache[collection] = {};
      _cache[collection][id] = _data;
    }
  }

  void getFromCache(String collection, String id, Map<String, dynamic> _data) {
    Map<String, Map<String, dynamic>> data = _cache[collection];
    if (data != null) {
      data[id] = _data;
    }
  }

  Map<String, dynamic> getItemFromCollection(String collection, String id) {
    Map<String, Map<String, dynamic>> data = _cache[collection];
    if (data != null) {
      return data[id];
    }
    return null;
  }

  Map<String, Map<String, dynamic>> getCollectionCache(String collection) {
    Map<String, Map<String, dynamic>> data = _cache[collection];
    if (data != null) {
      return data;
    }
    return Map<String, Map<String, dynamic>>();
  }

  Future<void> clear() {
    return Future(() async {
      try {
        _cache.clear();
        await save();
      } catch (e) {
        API().reportError(e);
      }
    });
  }

  Future<void> save() async {
    return Future(() async {
      try {
        var dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        var dbPath = dir.path + "/simply.db";
        File file = File(dbPath);
        await file.writeAsString(jsonEncode(_cache, toEncodable: customEncode));
      } catch (e) {
        API().reportError(e);
        print(e);
      }
    });
  }

  Future<void> initialize() async {
    trySyncToServer();
    return Future(() async {
      try {
        var dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        var dbPath = dir.path + "/simply.db";
        File file = File(dbPath);
        bool exists = await file.exists();
        if (exists) {
          String jsonObjectString = await file.readAsString();
          _cache = jsonDecode(jsonObjectString, reviver: customDecode)
              as Map<String, dynamic>;
        } else {
          _cache = Map<String, Map<String, Map<String, dynamic>>>();
        }
      } catch (e) {
        API().reportError(e);
        print(e);
      }
    });
  }

  void removeFromQueue(String collection, Map<String, dynamic> item) async {
    try {
      removeFromCache(collection, item["id"]);
    } catch (e) {
      API().reportError(e);
    }
  }

  void trySyncToServer() async {
    await Future.delayed(Duration(milliseconds: 1000));
    try {
      await save();
      Map<String, Map<String, dynamic>> queue;

      try {
        queue = getCollectionCache("query");
      } catch (e) {}

      if (queue == null || queue.isEmpty) {
        trySyncToServer();
        return;
      }

      try {
        queue.forEach((key, data) async {
          switch (data["action"]) {
            case "delete":
              {
                var doc = await API()
                    .database()
                    .collection(data["collectionRef"])
                    .document(data["id"]);
                var response = await doc.deleteImpl(data["time"]);
                if (response != null) {
                  if (response.statusCode == 400 ||
                      response.statusCode == 200) {
                    print("sent ${data["id"]} to cloud");
                    removeFromQueue(data["collectionRef"], data);
                  }
                }
              }
              break;
            case "update":
              var doc = await API()
                  .database()
                  .collection(data["collectionRef"])
                  .document(data["id"]);
              var response = await doc.updateImpl(data["data"], data["time"]);
              if (response != null) {
                if (response.statusCode == 400 || response.statusCode == 200) {
                  print("sent ${data["id"]} to cloud");
                  removeFromQueue(data["collectionRef"], data);
                }
              }
              break;
            case "add":
              var response = await API()
                  .database()
                  .collection(data["collectionRef"])
                  .addImpl(data["id"], data["data"], data["time"]);

              if (response != null) {
                if (response.statusCode == 400 || response.statusCode == 200) {
                  print("sent ${data["id"]} to cloud");
                  removeFromQueue(data["collectionRef"], data);
                }
              }
              break;
          }
        });
      } catch (e) {
        print(e);
      }
    } catch (e) {
      API().reportError(e);
    }

    await Future.delayed(Duration(milliseconds: 100));
    trySyncToServer();
  }

  void queueDelete(String collection, String id) {
    Future(() async {
      try {
        updateToCache("query", id, {
          "queue": true,
          "id": id,
          "collectionRef": collection,
          "action": "delete",
          "time": DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        API().reportError(e);
      }
    });
  }

  void queueUpdate(String collection, String id, Map<String, dynamic> data) {
    Future(() async {
      try {
        updateToCache("query", id, {
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
    });
  }

  void queueAdd(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    Future(() async {
      try {
        updateToCache("query", id, {
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
    });
  }

  void listenForChanges(Subscription sub) {
    /* var store = StoreRef.main();
    Filter filter = filterFromQuery(sub.target, sub.query);
    var query = store.query(finder: Finder(filter: filter));
    query.onSnapshots(db).listen((event) async {
      for (var change in event) {
        if (await change.ref.exists(db)) {
          sub.documents
              .removeWhere((element) => element.id == change.value["id"]);
          continue;
        }

        Map<String, dynamic> value = change.value;
        String id = value["id"];

        Map<String, dynamic> objCopy = Map.from(value);
        objCopy.remove("id");
        objCopy.remove("collection");

        var doc = sub.documents
            .firstWhere((element) => element.id == id, orElse: () => null);

        if (doc != null) {
          doc.data = objCopy;
        } else {
          doc = Document(true, id, sub.target, objCopy);
        }
      }
      sub.controller.add(sub.documents);
    }).onError((e) {
      assert(false, e);
    });*/
  }

  Future<String> insertDocument(
      String collection, String id, Map<String, dynamic> data) async {
    return Future(() async {
      try {
        Map<String, dynamic> dataCopy = Map.from(data);
        dataCopy["collection"] = collection;
        dataCopy["id"] = id;
        updateToCache(collection, id, dataCopy);
      } catch (e) {
        API().reportError(e);
      }

      return id;
    });
  }

  void updateDocument(
      String collection, String id, Map<String, dynamic> data) async {
    Future(() async {
      Map<String, dynamic> dataCopy = Map.from(data);
      dataCopy["collection"] = collection;
      try {
        Map<String, dynamic> dataCopy = Map.from(data);
        dataCopy["collection"] = collection;
        dataCopy["id"] = id;
        updateToCache(collection, id, dataCopy);
      } catch (e) {
        API().reportError(e);
      }
    });
  }

  Future<void> removeDocument(String collection, String id) async {
    return Future(() async {
      try {
        removeFromCache(collection, id);
      } catch (e) {
        API().reportError(e);
      }
    });
  }

  Future<Document> getDocument(String collection, String id) {
    return new Future(() async {
      Document doc = Document(false, id, collection, {});

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

        Map<String, dynamic> sendData = {};
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
    });
  }

  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries, String orderBy,
      {int start, int end, bool orderUp = true}) async {
    List<Document> docs = [];

    try {
      Map<String, Map<String, dynamic>> cachedCollection =
          getCollectionCache(collection);

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
          if (isSatisfied) docs.add(Document(true, key, collection, value));
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

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:sqflite/sqflite.dart';
import 'package:simply_sdk/socket.dart';

import 'collection.dart';
import 'document.dart';
import 'simply_sdk.dart';

class Cache {
  Database db;

  void removeFromQueue(String collection, Map<String, dynamic> item) async {
    try {
      await db.delete("query", where: "id=${item["id"]}&queue=true");
    } catch (e) {
      assert(false, e);
    }
  }

  void trySyncToServer() async {
    await Future.delayed(Duration(milliseconds: 1000));
    try {
      var queue = await db.query("query");

      if (queue.isEmpty) {
        trySyncToServer();
        return;
      }

      try {
        for (var data in queue) {
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
        }
      } catch (e) {
        print(e);
      }
    } catch (e) {
      assert(false, e);
    }

    await Future.delayed(Duration(milliseconds: 100));
    trySyncToServer();
  }

  Future<void> clear() {
    return Future(() async {
      try {
        var dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        var dbPath = dir.path + "/simply.db";
        await deleteDatabase(dbPath);
      } catch (e) {
        assert(false, e);
      }
    });
  }

  void queueDelete(String collection, String id) {
    Future(() async {
      try {
        await db.insert("query", {
          "queue": true,
          "id": id,
          "collectionRef": collection,
          "action": "delete",
          "time": DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        assert(false, e);
      }
    });
  }

  void queueUpdate(String collection, String id, Map<String, dynamic> data) {
    Future(() async {
      try {
        await db.insert("query", {
          "queue": true,
          "id": id,
          "collectionRef": collection,
          "action": "update",
          "data": data,
          "time": DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        assert(false, e);
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
        await db.insert("query", {
          "queue": true,
          "id": id,
          "collectionRef": collection,
          "action": "add",
          "data": data,
          "time": DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        assert(false, e);
      }
    });
  }

  Future<void> initialize() async {
    if (db != null) return;
    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = dir.path + "/simply.db";

    db = await openDatabase(dbPath);
    assert(db != null);

    trySyncToServer();
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
    Future(() async {
      try {
        var dataCopy = Map.from(data);
        dataCopy["collection"] = collection;
        dataCopy["id"] = id;
        await db.insert(collection, dataCopy);
      } catch (e) {
        assert(false, e);
      }

      return id;
    });
  }

  void updateDocument(
      String collection, String id, Map<String, dynamic> data) async {
    Future(() async {
      var dataCopy = Map.from(data);
      dataCopy["collection"] = collection;
      try {
        var dataCopy = Map.from(data);
        dataCopy["collection"] = collection;
        dataCopy["id"] = id;
        await db.update(collection, dataCopy, where: "id=$id&queue=false");
      } catch (e) {
        assert(false, e);
      }
    });
  }

  Future<void> removeDocument(String collection, String id) async {
    return Future(() async {
      try {
        await db.delete(collection, where: "id=$id&queue=false");
      } catch (e) {
        assert(false, e);
      }
    });
  }

  Future<Document> getDocument(String collection, String id) {
    return new Future(() async {
      Document doc = Document(false, id, collection, {});

      try {
        List<Map<String, dynamic>> docList =
            await db.query(collection, where: "id=$id");
        if (docList == null || docList.isEmpty) {
          return doc;
        }

        Map<String, dynamic> docData = docList[0];
        Map<String, dynamic> sendData = {};
        docData.forEach((key, value) {
          if (key != "id" && key != "collection") {
            sendData[key] = value;
          }
        });
        doc.data = sendData;
        doc.exists = true;
      } catch (e) {
        assert(false, e);
      }

      return doc;
    });
  }

  String filterFromQuery(Map<String, Query> queries) {
    String filter;
    if (queries.length == 1) {
      var field = queries.keys.first;
    } else {
      List<String> filters = [];
      for (var key in queries.keys) {
        String filter = queries[key].getCacheMethod() +
            jsonEncode(queries[key].getValue(), toEncodable: customEncode);
        filters.add(filter);
      }

      filter = filters.join("&");
    }
    return filter;
  }

  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries, String orderBy,
      {int start, int end}) async {
    List<Document> docs = [];

    String filter = filterFromQuery(queries);

    try {
      var foundDocs = await db.query(collection,
          where: filter, groupBy: orderBy, offset: start, limit: end);
      for (var foundDoc in foundDocs) {
        Map<String, dynamic> data = Map.from(foundDoc);

        Map<String, dynamic> sendData = {};
        data.forEach((key, value) {
          if (key != "id" && key != "collection") {
            sendData[key] = value;
          }
        });

        Document doc = Document(true, foundDoc["id"], collection, sendData);
        docs.add(doc);
      }
    } catch (e) {
      assert(false, e);
    }

    return docs;
  }
}

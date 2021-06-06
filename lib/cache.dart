import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_cloud_firestore_type_adapters/type_adapters.dart';
import 'package:simply_sdk/socket.dart';

import 'collection.dart';
import 'document.dart';
import 'simply_sdk.dart';

class Cache {
  Database db;

  void removeFromQueue(Map<String, dynamic> item) {
    var store = StoreRef.main();
    store.delete(db, finder: Finder(filter: Filter.equals("id", item["id"])));
  }

  Map<String, dynamic> convertToTimestamps(Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is DateTime) {
        source[key] = fir.Timestamp.fromDate(value);
      }
    });
  }

  void trySyncToServer() async {
    await Future.delayed(Duration(milliseconds: 1000));
    var store = StoreRef.main();
    var queue = await store
        .query(finder: Finder(filter: Filter.notNull("queue")))
        .getSnapshots(db);

    if (queue.isEmpty) {
      trySyncToServer();
      return;
    }
    try {
      for (var item in queue) {
        Map<String, dynamic> data = item.value;

        switch (data["action"]) {
          case "delete":
            {
              var doc = await API()
                  .database()
                  .collection(data["collectionRef"])
                  .document(data["id"]);
              var response = await doc.deleteImpl();
              if (response != null) {
                if (response.statusCode == 400 || response.statusCode == 200) {
                  print("sent ${data["id"]} to cloud");
                  removeFromQueue(data);
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
                removeFromQueue(data);
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
                removeFromQueue(data);
              }
            }
            break;
        }
      }
    } catch (e) {
      print(e);
    }

    await Future.delayed(Duration(milliseconds: 100));
    trySyncToServer();
  }

  Future<void> clear() {
    return Future(() async {
      var store = StoreRef.main();
      await store.drop(db);
    });
  }

  void queueDelete(String collection, String id) {
    var store = StoreRef.main();
    store.add(db, {
      "queue": true,
      "collectionRef": collection,
      "id": id,
      "action": "delete",
      "time": DateTime.now().millisecondsSinceEpoch
    });
  }

  void queueUpdate(String collection, String id, Map<String, dynamic> data) {
    var store = StoreRef.main();
    store.add(db, {
      "queue": true,
      "collectionRef": collection,
      "id": id,
      "action": "update",
      "data": convertToTimestamps(data),
      "time": DateTime.now().millisecondsSinceEpoch
    });
  }

  void queueAdd(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    var store = StoreRef.main();
    store.add(db, {
      "queue": true,
      "collectionRef": collection,
      "id": id,
      "action": "add",
      "data": convertToTimestamps(data),
      "time": DateTime.now().millisecondsSinceEpoch
    });
  }

  Future<void> initialize() async {
    if (db != null) return;

    DatabaseFactory dbFactory = databaseFactoryIo;

    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = dir.path + "/simply.db";

    db = await dbFactory.openDatabase(dbPath, codec: sembastFirestoreCodec);
    trySyncToServer();
  }

  void listenForChanges(Subscription sub) {
    var store = StoreRef.main();
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
    });
  }

  Future<String> insertDocument(
      String collection, String id, Map<String, dynamic> data) async {
    var store = StoreRef.main();

    var dataCopy = Map.from(data);
    dataCopy["collection"] = collection;
    dataCopy["id"] = id;

    await store.add(
      db,
      convertToTimestamps(dataCopy),
    );

    return id;
  }

  void updateDocument(String collection, String id, Map<String, dynamic> data) {
    var store = StoreRef.main();

    var dataCopy = Map.from(data);
    dataCopy["collection"] = collection;

    store.update(db, convertToTimestamps(dataCopy),
        finder: Finder(
            filter: Filter.and([
          Filter.equals("id", id),
          Filter.equals("collection", collection)
        ])));
  }

  Future<void> removeDocument(String collection, String id) {
    return Future(() async {
      var store = StoreRef.main();
      await store.delete(db,
          finder: Finder(
              filter: Filter.and([
            Filter.equals("id", id),
            Filter.equals("collection", collection)
          ])));
    });
  }

  Future<Document> getDocument(String collection, String id) {
    return new Future(() async {
      Document doc = Document(false, id, collection, {});

      var store = StoreRef.main();

      RecordSnapshot data = await store.findFirst(db,
          finder: Finder(
              filter: Filter.and([
            Filter.equals("id", id),
            Filter.equals("collection", collection)
          ])));

      if (data == null) {
        return doc;
      }

      Map<String, dynamic> docData = Map.from(data.value);
      Map<String, dynamic> sendData = {};
      docData.forEach((key, value) {
        if (key != "id" && key != "collection") {
          sendData[key] = value;
        }
      });
      doc.data = sendData;
      doc.exists = true;

      return doc;
    });
  }

  Filter filterFromQuery(String collection, Map<String, Query> queries) {
    Filter filter;
    if (queries.length == 1) {
      var field = queries.keys.first;
      Query query = queries[field];
      filter = Filter.and(
          [Filter.equals("collection", collection), query.getFilter(field)]);
    } else {
      List<Filter> filters = [];
      for (var key in queries.keys) {
        filters.add(queries[key].getFilter(key));
      }

      filters.add(Filter.equals("collection", collection));

      filter = Filter.and(filters);
    }
    return filter;
  }

  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries, String orderBy,
      {int start, int end}) async {
    List<Document> docs = [];
    var store = StoreRef.main();

    Filter filter = filterFromQuery(collection, queries);

    var foundDocs = await store.find(db,
        finder: Finder(
            filter: filter,
            sortOrders: orderBy == null ? [] : [SortOrder(orderBy)],
            offset: start,
            limit: end));

    for (var foundDoc in foundDocs) {
      Map<String, dynamic> data = Map.from(foundDoc.value);

      Map<String, dynamic> sendData = {};
      data.forEach((key, value) {
        if (key != "id" && key != "collection") {
          sendData[key] = value;
        }
      });

      Document doc = Document(true, foundDoc.value["id"], collection, sendData);
      docs.add(doc);
    }

    return docs;
  }
}

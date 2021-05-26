import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'collection.dart';
import 'document.dart';

class Cache {
  Database db;

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
      "data": data,
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
      "data": data,
      "time": DateTime.now().millisecondsSinceEpoch
    });
  }

  Future<void> initialize() async {
    DatabaseFactory dbFactory = databaseFactoryIo;

    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = dir.path + "/simply.db";

    db = await dbFactory.openDatabase(dbPath);
  }

  Future<String> insertDocument(
      String collection, String id, Map<String, dynamic> data) async {
    var store = StoreRef.main();

    data["collection"] = collection;
    data["id"] = id;

    await store.add(
      db,
      data,
    );

    return id;
  }

  void updateDocument(String collection, String id, Map<String, dynamic> data) {
    var store = StoreRef.main();

    data["collection"] = collection;

    store.update(db, data,
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
      docData.remove("collection");
      docData.remove("id");
      doc.data = docData;
      doc.exists = true;

      return doc;
    });
  }

  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries, String orderBy,
      {int start, int end}) async {
    List<Document> docs = [];
    var store = StoreRef.main();

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

    var foundDocs = await store.find(db,
        finder: Finder(
            filter: filter,
            sortOrders: orderBy == null ? [] : [SortOrder(orderBy)],
            offset: start,
            limit: end));

    for (var foundDoc in foundDocs) {
      Map<String, dynamic> data = Map.from(foundDoc.value);
      data.remove("collection");
      data.remove("id");

      Document doc = Document(true, foundDoc.value["id"], collection, data);
      docs.add(doc);
    }

    return docs;
  }

  // Todo: Listeners to data changes
}

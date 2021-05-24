import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'collection.dart';
import 'document.dart';

class Cache {
  Database db;

  Future<void> clear() async {
    var store = StoreRef.main();
    await store.drop(db);
  }

  Future<void> initialize() async {
    DatabaseFactory dbFactory = databaseFactoryIo;

    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = dir.path + "/simply.db";

    db = await dbFactory.openDatabase(dbPath);
  }

  Future<dynamic> insertDocument(
      String collection, Map<String, dynamic> data) async {
    var store = StoreRef.main();

    data["collection"] = collection;

    return await store.add(
      db,
      data,
    );
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

  void removeDocument(String collection, String id) {
    var store = StoreRef.main();
    store.delete(db,
        finder: Finder(
            filter: Filter.and([
          Filter.equals("id", id),
          Filter.equals("collection", collection)
        ])));
  }

  Future<Document> getDocument(String collection, String id) async {
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

      doc.data = data.value;

      return doc;
    });
  }

  Future<List<Document>> searchForDocuments(
      String collection, Map<String, Query> queries) async {
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

    var foundDocs = await store.find(db, finder: Finder(filter: filter));

    for (var foundDoc in foundDocs) {
      Document doc = Document(true, foundDoc.key, collection, foundDoc.value);
      docs.add(doc);
    }

    return docs;
  }
}

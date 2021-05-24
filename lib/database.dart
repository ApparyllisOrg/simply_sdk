import 'batch.dart';
import 'collection.dart';

class Database {
  Collection collection(String id) {
    return new Collection(id);
  }

  Batch batch(String collection) {
    return new Batch(collection);
  }
}

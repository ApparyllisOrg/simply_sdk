import 'dart:convert';
import 'collection.dart';

class Database {
  Collection collection(String id) {
    return new Collection(id);
  }
}

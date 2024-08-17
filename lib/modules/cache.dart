import 'dart:async';
import 'dart:convert';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/types/document.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simply_sdk/helpers.dart';

import '../simply_sdk.dart';

class Cache {
  Map<String, dynamic> _cache = Map<String, dynamic>();

  void removeFromCache(String type, String id) {
    if (_cache[type.toLowerCase()] != null) {
      _cache[type.toLowerCase()].remove(id);
    }
    markDirty();
  }

  void updateToCache(String type, String id, Map<String, dynamic> _data) {
    final Map<String, dynamic>? coll = _cache[type.toLowerCase()];
    if (coll != null) {
      if (coll.containsKey(id)) {
        final Map<String, dynamic> dat = _cache[type.toLowerCase()][id];
        dat.addAll(_data);
        _cache[type.toLowerCase()][id] = dat;
      } else {
        _cache[type.toLowerCase()][id] = _data;
      }
    } else {
      _cache[type.toLowerCase()] = Map<String, dynamic>();
      _cache[type.toLowerCase()][id] = _data;
    }

    markDirty();
  }

  Map<String, dynamic>? getItemFromType(String type, String id) {
    final Map<String, dynamic>? data = _cache[type.toLowerCase()] as Map<String, dynamic>?;
    if (data != null) {
      final Map<String, dynamic>? docData = data[id] as Map<String, dynamic>?;
      if (docData != null) {
        docData.remove('id');
        return docData;
      }
    }
    return null;
  }

  Map<String, dynamic> getTypeCache(String type) {
    if (_cache.containsKey(type.toLowerCase())) {
      Map<String, dynamic> data = _cache[type.toLowerCase()];
      return data.cast<String, dynamic>();
    }
    return Map<String, dynamic>();
  }

  void clearTypeCache(String type) {
    _cache.remove(type.toLowerCase());
    markDirty();
  }

  bool hasDataInCacheForType(String type) {
    return _cache.containsKey(type.toLowerCase()) && (_cache[type.toLowerCase()] as Map<String, dynamic>).isNotEmpty;
  }

  void cacheListOfDocuments(List<Document<dynamic>> docs) {
    docs.forEach((element) {
      updateToCache(element.type.toLowerCase(), element.id, (element.dataObject as DocumentData).toJson());
    });
    markDirty();
  }

  Future<void> clear() {
    return Future(() async {
      try {
        _cache.clear();
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
    saveTimer = Timer(const Duration(milliseconds: 10), save);
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
        html.window.localStorage['db'] = jsonEncode(_cache, toEncodable: customEncode);

        API().debug().logFine('Saved cache');
      } catch (e) {
        dirty = true;
        API().reportError(e, StackTrace.current);
        print(e);
      }
    } else {
      try {
        dirty = false;

        final dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        final dbPath = '${dir.path}/simply.db';

        // Save cache
        final File file = File(dbPath);
        file.writeAsStringSync(jsonEncode(_cache, toEncodable: customEncode));

        print('Saved cache');
      } catch (e) {
        dirty = true;
        API().reportError(e, StackTrace.current);
        print(e);
      }
    }
  }

  String lastInitializeFor = '';
  bool isInitialzed = false;
  Future<void> initialize(String initializeFor) async {
    if (lastInitializeFor != initializeFor) {
      lastInitializeFor = initializeFor;
    } else {
      return;
    }

    await Future(() async {
      if (kIsWeb) {
        final bool dbExists = html.window.localStorage.containsKey('db');
        _cache = dbExists ? jsonDecode(html.window.localStorage['db'] ?? '', reviver: customDecode) as Map<String, dynamic> : Map<String, dynamic>();
      } else {
        try {
          final dir = await getApplicationDocumentsDirectory();
          await dir.create(recursive: true);
          final dbPath = '${dir.path}/simply.db';

          final File file = File(dbPath);
          final bool exists = await file.exists();

          if (exists) {
            final String jsonObjectString = await file.readAsString();
            if (jsonObjectString.isNotEmpty) {
              _cache = ((jsonDecode(jsonObjectString, reviver: customDecode)) ?? Map<String, dynamic>()) as Map<String, dynamic>;
            }
          } else {
            _cache = Map<String, dynamic>();
          }
        } catch (e) {
          API().reportError(e, StackTrace.current);
          print(e);
          _cache = Map<String, dynamic>();
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      isInitialzed = true;
      save();
    });
  }

  String insertDocument(String type, String id, Map<String, dynamic> data) {
    final Map<String, dynamic> dataCopy = Map.from(data);
    dataCopy['type'] = type.toLowerCase();
    dataCopy['id'] = id;
    updateToCache(type.toLowerCase(), id, dataCopy);
    return id;
  }

  Future<void> updateDocument(String type, String id, Map<String, dynamic> data) async {
    final Map<String, dynamic> dataCopy = Map.from(data);
    updateToCache(type.toLowerCase(), id, dataCopy);
  }

  Future<void> removeDocument(String type, String id) async {
    removeFromCache(type.toLowerCase(), id);
  }

  Map<String, dynamic>? getDocument(String type, String id) {
    try {
      final Map<String, dynamic> docData = getItemFromType(type, id) ?? {};

      if (docData.isEmpty) {
        return null;
      }

      final Map<String, dynamic> sendData = Map<String, dynamic>();
      docData.forEach((key, value) {
        if (key != 'id' && key != 'type') {
          sendData[key] = value;
        }
      });

      return docData;
    } catch (e) {
      print(e);
    }

    return null;
  }

  List<Document<ObjectType>> getDocumentsWhere<ObjectType>(
      String type, bool Function(Document<ObjectType>) where, ObjectType Function(Map<String, dynamic>) toDocumentData) {
    final List<Document<ObjectType>> docs = [];

    final Map<String, dynamic> collection = getTypeCache(type);

    collection.forEach((key, value) {
      final ObjectType dataType = toDocumentData(value as Map<String, dynamic>);
      final Document<ObjectType> tempDoc = Document<ObjectType>(true, key, dataType, type);
      if (where(tempDoc)) {
        docs.add(tempDoc);
      }
    });

    return docs;
  }

  List<Document<ObjectType>> getDocuments<ObjectType>(String type, ObjectType Function(Map<String, dynamic>) toDocumentData) {
    final List<Document<ObjectType>> docs = [];

    final Map<String, dynamic> collection = getTypeCache(type);

    collection.forEach((key, value) {
      final ObjectType dataType = toDocumentData(value as Map<String, dynamic>);
      final Document<ObjectType> tempDoc = Document<ObjectType>(true, key, dataType, type);

      docs.add(tempDoc);
    });

    return docs;
  }
}

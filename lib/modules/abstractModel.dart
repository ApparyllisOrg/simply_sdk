import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_file/universal_file.dart';

abstract class AbstractModel extends ChangeNotifier {
  void reset([bool notify = true]) {
    copyFromJson({});
    if (notify) notifyListeners();
    scheduleSave();
  }

  void notify() => notifyListeners();

  bool _isSaveScheduled = false;

  void scheduleSave() async {
    if (_isSaveScheduled) {
      return;
    }
    _isSaveScheduled = true;
    await Future.delayed(const Duration(seconds: 1));
    save();
    _isSaveScheduled = false;
  }

  String getFileName();

  Future<String> getFilePath() async {
    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return dir.path + "/${getFileName()}.db";
  }

  Future<void> load() async {
    if (kIsWeb) {
      // TODO: Add web load
    } else {
      String filePath = await getFilePath();
      File file = File(filePath);
      bool bExists = await file.exists();

      if (bExists) {
        String string = await file.readAsString().catchError((e, s) {
          return "{}";
        });
        copyFromJson(jsonDecode(string));
      }
    }
  }

  Future<void> save() async {
    if (kIsWeb) {
      // TODO: Add web save
    } else {
      String filePath = await getFilePath();
      File file = File(filePath);
      file.writeAsStringSync(jsonEncode(toJson()));
    }
  }

  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  dynamic copyFromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  List<T> toList<T>(dynamic json, dynamic Function(dynamic) fromJson) {
    final List<T> list = (json as Iterable?)
            ?.map((e) {
              return e == null ? e : fromJson(e) as T?;
            })
            .where((e) => e != null)
            .whereType<T>()
            .toList() ??
        [];

    return list;
  }
}
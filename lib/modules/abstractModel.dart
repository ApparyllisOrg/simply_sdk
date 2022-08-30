import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:universal_file/universal_file.dart';

abstract class AbstractModel extends ChangeNotifier {
  File? _file;

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

  Future<void> load() async {
    final file = File("");
    if (file == null) {
      return;
    }

    String string = await file.readAsString().catchError((e, s) {
      return "{}";
    });

    copyFromJson(jsonDecode(string));
  }

  Future<void> save() async => _file?.writeAsString(jsonEncode(toJson()));

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

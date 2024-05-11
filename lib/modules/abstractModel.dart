import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_file/universal_file.dart';
import 'package:universal_html/html.dart' as html;

abstract class AbstractModel extends ChangeNotifier {
  void reset([bool notify = true]) {
    copyFromJson({});
    if (notify) notifyListeners();
    scheduleSave();
  }

  void notify() => notifyListeners();

  bool _isSaveScheduled = false;

  Future<void> scheduleSave() async {
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
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return '${dir.path}/${getFileName()}.db';
  }

  Future<void> load() async {
    if (kIsWeb) {
      final bool dbExists = html.window.localStorage.containsKey(getFileName());
      if (dbExists) {
        final dynamic storedData = dbExists ? (html.window.localStorage[getFileName()] ?? '{}') : '{}';
        if (storedData is String) {
          copyFromJson(jsonDecode(storedData));
        } else {
          copyFromJson(storedData as Map<String, dynamic>);
        }
      }
    } else {
      final String filePath = await getFilePath();
      final File file = File(filePath);
      final bool bExists = await file.exists();

      if (bExists) {
        final String string = await file.readAsString().catchError((e, s) {
          return '{}';
        });

        try {
          copyFromJson(jsonDecode(string));
        } catch (e) {
          copyFromJson({});
        }
      } else {
        copyFromJson({});
      }
    }
  }

  Future<void> save() async {
    if (kIsWeb) {
      try {
        html.window.localStorage[getFileName()] = jsonEncode(toJson());
      } catch (e) {
        print(e);
      }
    } else {
      final String filePath = await getFilePath();
      final File file = File(filePath);
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

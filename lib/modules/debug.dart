import 'package:flutter/foundation.dart';
import "package:universal_html/html.dart" as html;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';

class Debug {
  Timer? _saveTimer;
  bool _bDirty = false;
  bool _isInitialized = false;
  List<String> _logs = [];

  List<String> getLogs() => _logs;

  void enable() {
    _saveTimer = Timer.periodic(Duration(seconds: 2), timerSave);
  }

  void timerSave(timer) {
    if (_bDirty) {
      save();
    }
  }

  void disable() {
    if (_saveTimer != null) {
      _saveTimer!.cancel();
      _saveTimer = null;
    }
  }

  Future<void> init() async {
    await load();
  }

  void logFine(String msg) {
    Logger.root.fine(msg);
    _bDirty = true;
    _logs.add("[${getLogTime()}] FINE: $msg");
  }

  void logInfo(String msg) {
    Logger.root.info(msg);
    _bDirty = true;
    _logs.add("[${getLogTime()}] INFO: $msg");
  }

  void logWarning(String msg) {
    Logger.root.warning(msg);
    _bDirty = true;
    _logs.add("[${getLogTime()}] WARN: $msg");
  }

  void logError(String msg) {
    Logger.root.severe(msg);
    _bDirty = true;
    _logs.add("[${getLogTime()}] ERR: $msg");
  }

  String getLogTime() => DateTime.now().toIso8601String();

  Future<void> load() async {
    await Future(() async {
      if (kIsWeb) {
        bool dbExists = html.window.localStorage.containsKey("logs");
        _logs = dbExists
            ? jsonDecode(
                html.window.localStorage["logs"] ?? "",
              ) as List<String>
            : [];
      } else {
        try {
          var dir = await getApplicationDocumentsDirectory();
          await dir.create(recursive: true);
          var dbPath = dir.path + "/logs.db";

          File file = File(dbPath);
          bool exists = await file.exists();

          if (exists) {
            String jsonObjectString = await file.readAsString();
            if (jsonObjectString.isNotEmpty) {
              _logs = ((jsonDecode(jsonObjectString)) ?? []) as List<String>;
            }
          } else {
            _logs = [];
          }
        } catch (e) {
          _logs = [];
          print(e);
        }
      }

      await Future.delayed(Duration(seconds: 1));
      _isInitialized = true;
      save();
    });
  }

  void save() async {
    // Limit to 1000 entries...
    if (_logs.length > 1000) {
      _logs = _logs.sublist(_logs.length - 1000, _logs.length);
    }

    if (kIsWeb) {
      try {
        html.window.localStorage["logs"] = jsonEncode(_logs);

        Logger.root.fine("Saved cache");
      } catch (e) {
        print(e);
      }
    } else {
      try {
        var dir = await getApplicationDocumentsDirectory();
        await dir.create(recursive: true);
        var dbPath = dir.path + "/logs.db";

        File file = File(dbPath);
        file.writeAsStringSync(jsonEncode(_logs));

        print("Saved cache");
      } catch (e) {
        print(e);
      }
    }
  }
}

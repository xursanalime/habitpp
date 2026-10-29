import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Holds log entries and settings, saving each to its JSON file after every change.
class AppState extends ChangeNotifier {
  AppState({this.file, this.settingsFile, List<LogEntry>? logs, Settings? settings})
    : logs = logs ?? [],
      settings = settings ?? Settings();

  /// Where data is saved; null keeps it in memory only (tests).
  final File? file;
  final File? settingsFile;
  final List<LogEntry> logs;
  final Settings settings;

  static Future<AppState> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/habitpp_data.json');
    final settingsFile = File('${dir.path}/habitpp_settings.json');
    final logs = <LogEntry>[];
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      for (final e in json['logs'] as List) {
        logs.add(LogEntry.fromJson(e as Map<String, dynamic>));
      }
    }
    var settings = Settings();
    if (await settingsFile.exists()) {
      settings = Settings.fromJson(jsonDecode(await settingsFile.readAsString()) as Map<String, dynamic>);
    }
    return AppState(file: file, settingsFile: settingsFile, logs: logs, settings: settings);
  }

  Future<void> add(LogEntry entry) async {
    logs.add(entry);
    notifyListeners();
    await _write(file, {'version': 1, 'logs': logs.map((e) => e.toJson()).toList()});
  }

  Future<void> updateSettings(void Function(Settings s) change) async {
    change(settings);
    notifyListeners();
    await _write(settingsFile, settings.toJson());
  }

  static Future<void> _write(File? file, Map<String, dynamic> json) async {
    if (file == null) return;
    await file.parent.create(recursive: true);
    // Write to a temp file first so a crash mid-write can't corrupt the data.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(json));
    await tmp.rename(file.path);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Holds all log entries and saves them to a JSON file after every change.
class AppState extends ChangeNotifier {
  AppState({this.file, List<LogEntry>? logs}) : logs = logs ?? [];

  /// Where data is saved; null keeps it in memory only (tests).
  final File? file;
  final List<LogEntry> logs;

  static Future<AppState> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/habitpp_data.json');
    final logs = <LogEntry>[];
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      for (final e in json['logs'] as List) {
        logs.add(LogEntry.fromJson(e as Map<String, dynamic>));
      }
    }
    return AppState(file: file, logs: logs);
  }

  Future<void> add(LogEntry entry) async {
    logs.add(entry);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final file = this.file;
    if (file == null) return;
    await file.parent.create(recursive: true);
    // Write to a temp file first so a crash mid-write can't corrupt the data.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode({
      'version': 1,
      'logs': logs.map((e) => e.toJson()).toList(),
    }));
    await tmp.rename(file.path);
  }
}

/// How a task's proof is measured.
enum MetricKind {
  /// Correct answers out of total questions; thresholds apply to the total.
  score,

  /// A plain amount (words, minutes, items).
  amount,
}

class TaskDef {
  const TaskDef({
    required this.id,
    required this.title,
    required this.time,
    required this.metric,
    required this.minimum,
    required this.full,
    required this.unit,
  });

  final String id;
  final String title;

  /// Planned start, "HH:mm".
  final String time;
  final MetricKind metric;

  /// Amount that still counts the day as done (bad-day dose).
  final int minimum;

  /// Amount for a full session.
  final int full;
  final String unit;
}

class LogEntry {
  const LogEntry({
    required this.date,
    required this.taskId,
    required this.value,
    this.total,
    this.note = '',
    required this.loggedAt,
  });

  /// Day the work counts for, "yyyy-mm-dd".
  final String date;
  final String taskId;

  /// Amount done, or correct answers for score tasks.
  final int value;

  /// Questions attempted, only for score tasks.
  final int? total;
  final String note;
  final DateTime loggedAt;

  Map<String, dynamic> toJson() => {
    'date': date,
    'taskId': taskId,
    'value': value,
    if (total != null) 'total': total,
    if (note.isNotEmpty) 'note': note,
    'loggedAt': loggedAt.toIso8601String(),
  };

  /// Correct-answer ratio for score entries, null otherwise.
  double? get accuracy => total != null && total! > 0 ? value / total! : null;

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    date: json['date'] as String,
    taskId: json['taskId'] as String,
    value: json['value'] as int,
    total: json['total'] as int?,
    note: (json['note'] as String?) ?? '',
    loggedAt: DateTime.parse(json['loggedAt'] as String),
  );
}

/// Local-only settings; the Telegram token never leaves this device's file.
class Settings {
  Settings({
    this.telegramToken = '',
    this.telegramChatId = '',
    this.remindAt2045 = true,
    this.autoReport = false,
    this.lastReminded,
    this.lastReported,
  });

  String telegramToken;
  String telegramChatId;
  bool remindAt2045;
  bool autoReport;

  /// Day keys guarding the once-a-day reminder and report.
  String? lastReminded;
  String? lastReported;

  bool get telegramReady => telegramToken.isNotEmpty && telegramChatId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'telegramToken': telegramToken,
    'telegramChatId': telegramChatId,
    'remindAt2045': remindAt2045,
    'autoReport': autoReport,
    'lastReminded': lastReminded,
    'lastReported': lastReported,
  };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    telegramToken: (json['telegramToken'] as String?) ?? '',
    telegramChatId: (json['telegramChatId'] as String?) ?? '',
    remindAt2045: (json['remindAt2045'] as bool?) ?? true,
    autoReport: (json['autoReport'] as bool?) ?? false,
    lastReminded: json['lastReminded'] as String?,
    lastReported: json['lastReported'] as String?,
  );
}

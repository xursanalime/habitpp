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

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        date: json['date'] as String,
        taskId: json['taskId'] as String,
        value: json['value'] as int,
        total: json['total'] as int?,
        note: (json['note'] as String?) ?? '',
        loggedAt: DateTime.parse(json['loggedAt'] as String),
      );
}

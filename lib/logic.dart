import 'models.dart';
import 'schedule.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Whole days left until the exam, counted by calendar date (never negative).
int daysUntilExam(DateTime now) {
  final days = examDate.difference(dateOnly(now)).inDays;
  return days < 0 ? 0 : days;
}

enum Level { none, started, minimum, full }

enum Alarm { ok, warning, red }

/// Amount compared against thresholds: questions attempted for score tasks.
int progressOf(TaskDef task, Iterable<LogEntry> entries) {
  var sum = 0;
  for (final e in entries) {
    sum += task.metric == MetricKind.score ? (e.total ?? 0) : e.value;
  }
  return sum;
}

Level levelOf(TaskDef task, int progress) {
  if (progress >= task.full) return Level.full;
  if (progress >= task.minimum) return Level.minimum;
  if (progress > 0) return Level.started;
  return Level.none;
}

class Debt {
  const Debt(this.date, this.task, this.progress);
  final DateTime date;
  final TaskDef task;
  final int progress;
}

class Tracker {
  Tracker(this.logs, {DateTime? start}) : start = dateOnly(start ?? trackingStart);

  final List<LogEntry> logs;
  final DateTime start;

  Iterable<LogEntry> _entries(DateTime day, String taskId, {bool onTimeOnly = false}) {
    final key = dayKey(day);
    return logs.where((e) =>
        e.date == key &&
        e.taskId == taskId &&
        (!onTimeOnly || dayKey(e.loggedAt) == key));
  }

  int progress(DateTime day, TaskDef task) => progressOf(task, _entries(day, task.id));

  Level level(DateTime day, TaskDef task) => levelOf(task, progress(day, task));

  /// All tasks reached the minimum on the day itself; late make-ups don't count.
  bool completedOnTime(DateTime day) => tasksFor(day).every((t) =>
      progressOf(t, _entries(day, t.id, onTimeOnly: true)) >= t.minimum);

  /// Tasks below minimum on tracked days before today, oldest first.
  List<Debt> debts(DateTime now) {
    final today = dateOnly(now);
    final result = <Debt>[];
    for (var d = start; d.isBefore(today); d = DateTime(d.year, d.month, d.day + 1)) {
      for (final t in tasksFor(d)) {
        final p = progress(d, t);
        if (p < t.minimum) result.add(Debt(d, t, p));
      }
    }
    return result;
  }

  /// Red after two missed days in a row, warning after one.
  Alarm alarm(DateTime now) {
    final today = dateOnly(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final before = DateTime(today.year, today.month, today.day - 2);
    bool missed(DateTime d) => !d.isBefore(start) && !completedOnTime(d);
    if (missed(yesterday) && missed(before)) return Alarm.red;
    if (missed(yesterday)) return Alarm.warning;
    return Alarm.ok;
  }

  /// Consecutive on-time days ending today (if done) or yesterday.
  int streak(DateTime now) {
    var d = dateOnly(now);
    if (!completedOnTime(d)) d = DateTime(d.year, d.month, d.day - 1);
    var count = 0;
    while (!d.isBefore(start) && completedOnTime(d)) {
      count++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return count;
  }
}

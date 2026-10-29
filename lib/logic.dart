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

enum DayStatus { beforeStart, future, today, onTime, late, missed }

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Monday of the week containing [d]; weekly counters reset every Monday.
DateTime weekStart(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

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
    return logs.where(
      (e) => e.date == key && e.taskId == taskId && (!onTimeOnly || dayKey(e.loggedAt) == key),
    );
  }

  int progress(DateTime day, TaskDef task) => progressOf(task, _entries(day, task.id));

  Level level(DateTime day, TaskDef task) => levelOf(task, progress(day, task));

  /// All tasks reached the minimum on the day itself; late make-ups don't count.
  bool completedOnTime(DateTime day) =>
      tasksFor(day).every((t) => progressOf(t, _entries(day, t.id, onTimeOnly: true)) >= t.minimum);

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

class WeekSummary {
  const WeekSummary({
    required this.start,
    required this.closedDays,
    required this.onTimeDays,
    required this.totals,
  });

  final DateTime start;

  /// Tracked days of this week that are already over (today excluded).
  final int closedDays;
  final int onTimeDays;

  /// Progress per task id summed over the week.
  final Map<String, int> totals;

  double? get rate => closedDays == 0 ? null : onTimeDays / closedDays;

  /// The Sunday audit rule from the habit system.
  String get verdict {
    final r = rate;
    if (r == null) return "Hafta endi boshlandi — birinchi kunni to'liq yop.";
    if (r < 0.5) {
      return "Kunlarning yarmidan kami bajarildi. Muammo sende emas — doza katta. "
          'Minimal dozani kichraytir.';
    }
    if (r >= 0.8) return "Zo'r hafta. 2 hafta shunday bo'lsa, dozani biroz oshir.";
    return 'Yomon emas. Maqsad: kunlarning 80% i. Bitta kunni ham ikki marta o\'tkazma.';
  }
}

extension TrackerStats on Tracker {
  DayStatus status(DateTime day, DateTime now) {
    final d = dateOnly(day);
    final today = dateOnly(now);
    if (d.isBefore(start)) return DayStatus.beforeStart;
    if (d.isAfter(today)) return DayStatus.future;
    if (completedOnTime(d)) return DayStatus.onTime;
    if (d == today) return DayStatus.today;
    final allMet = tasksFor(d).every((t) => progress(d, t) >= t.minimum);
    return allMet ? DayStatus.late : DayStatus.missed;
  }

  WeekSummary week(DateTime now) {
    final today = dateOnly(now);
    final monday = weekStart(today);
    var closed = 0;
    var onTime = 0;
    final totals = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = addDays(monday, i);
      if (d.isAfter(today)) break;
      for (final t in tasksFor(d)) {
        totals[t.id] = (totals[t.id] ?? 0) + progress(d, t);
      }
      if (d == today || d.isBefore(start)) continue;
      closed++;
      if (completedOnTime(d)) onTime++;
    }
    return WeekSummary(start: monday, closedDays: closed, onTimeDays: onTime, totals: totals);
  }

  /// Score entries (oldest first) for the accuracy chart.
  List<LogEntry> scoreEntries() {
    final list = logs.where((e) => e.accuracy != null).toList()
      ..sort(
        (a, b) => a.date.compareTo(b.date) != 0 ? a.date.compareTo(b.date) : a.loggedAt.compareTo(b.loggedAt),
      );
    return list;
  }

  /// Daily total for one task id over the last [days] days, oldest first.
  List<int> dailyTotals(String taskId, DateTime now, int days) {
    final today = dateOnly(now);
    return [
      for (var i = days - 1; i >= 0; i--)
        logs
            .where((e) => e.taskId == taskId && e.date == dayKey(addDays(today, -i)))
            .fold(0, (sum, e) => sum + e.value),
    ];
  }
}

/// Plain-text daily report for Telegram or pasting to Claude at 20:59.
String buildReport(Tracker tracker, DateTime now) {
  const weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
  final today = dateOnly(now);
  final tasks = tasksFor(today);
  final done = tasks.where((t) => tracker.progress(today, t) >= t.minimum).length;
  final b = StringBuffer()
    ..writeln('📊 Habitpp · ${dayKey(today)} (${weekdays[today.weekday - 1]})')
    ..writeln('⏳ IELTS gacha ${daysUntilExam(now)} kun')
    ..writeln('✅ Bugun: $done/${tasks.length}')
    ..writeln();
  for (final t in tasks) {
    final p = tracker.progress(today, t);
    final mark = switch (levelOf(t, p)) {
      Level.full => '✅✅',
      Level.minimum => '✅',
      Level.started => '🟡',
      Level.none => '❌',
    };
    var line = '$mark ${t.title}: $p/${t.minimum} ${t.unit}';
    if (t.metric == MetricKind.score) {
      final entries = tracker.logs.where((e) => e.date == dayKey(today) && e.taskId == t.id);
      final correct = entries.fold(0, (s, e) => s + e.value);
      if (p > 0) line += ' (to\'g\'ri: $correct/$p, ${(correct * 100 / p).round()}%)';
    }
    b.writeln(line);
  }
  final notes = tracker.logs
      .where((e) => e.date == dayKey(today) && e.note.isNotEmpty)
      .map((e) => '• ${e.note}');
  if (notes.isNotEmpty) {
    b
      ..writeln()
      ..writeln('📝 Izohlar:');
    notes.forEach(b.writeln);
  }
  b
    ..writeln()
    ..writeln('🔥 Ketma-ket: ${tracker.streak(now)} kun')
    ..write('🔴 Qarz: ${tracker.debts(now).length} ta');
  return b.toString();
}

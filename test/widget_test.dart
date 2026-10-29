import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitpp/logic.dart';
import 'package:habitpp/main.dart';
import 'package:habitpp/models.dart';
import 'package:habitpp/schedule.dart';
import 'package:habitpp/store.dart';

/// Entries that bring every task of [day] exactly to its minimum.
List<LogEntry> minimumDay(DateTime day, {DateTime? loggedAt}) => [
  for (final t in tasksFor(day))
    LogEntry(
      date: dayKey(day),
      taskId: t.id,
      value: t.metric == MetricKind.score ? 1 : t.minimum,
      total: t.metric == MetricKind.score ? t.minimum : null,
      loggedAt: loggedAt ?? day.add(const Duration(hours: 20)),
    ),
];

void main() {
  final fri = DateTime(2026, 10, 30); // trackingStart
  final sat = DateTime(2026, 10, 31);
  final sun = DateTime(2026, 11, 1);

  test('daysUntilExam counts calendar days', () {
    expect(daysUntilExam(DateTime(2026, 10, 29, 23, 59)), 62);
    expect(daysUntilExam(DateTime(2026, 12, 30, 8)), 0);
    expect(daysUntilExam(DateTime(2027, 1, 5)), 0);
  });

  test('schedule rotates reading, listening and the Sunday mock', () {
    expect(tasksFor(DateTime(2026, 11, 2)).first.id, 'reading');
    expect(tasksFor(DateTime(2026, 11, 3)).first.id, 'listening');
    expect(tasksFor(sun).first.id, 'mock');
    expect(tasksFor(sun), hasLength(6));
  });

  test('score tasks count questions attempted, not correct answers', () {
    final entries = [LogEntry(date: '2026-11-02', taskId: 'reading', value: 5, total: 13, loggedAt: fri)];
    expect(levelOf(reading, progressOf(reading, entries)), Level.minimum);
  });

  test('missed tasks become debt from tracking start', () {
    expect(Tracker([]).debts(sun.add(const Duration(hours: 9))), hasLength(12));
    expect(Tracker(minimumDay(fri)).debts(sun), hasLength(6));
    expect(Tracker([]).debts(fri.add(const Duration(hours: 9))), isEmpty);
  });

  test('alarm: warning after one missed day, red after two', () {
    expect(Tracker([]).alarm(fri), Alarm.ok);
    expect(Tracker([]).alarm(sat), Alarm.warning);
    expect(Tracker([]).alarm(sun), Alarm.red);
    expect(Tracker(minimumDay(sat)).alarm(sun), Alarm.ok);
  });

  test('late make-up clears debt but still counts as a missed day', () {
    final late = minimumDay(fri, loggedAt: sat.add(const Duration(hours: 8)));
    final tracker = Tracker(late);
    expect(tracker.debts(sat), isEmpty);
    expect(tracker.alarm(sat), Alarm.warning);
  });

  test('streak counts consecutive on-time days', () {
    final logs = [...minimumDay(fri), ...minimumDay(sat)];
    expect(Tracker(logs).streak(sun.add(const Duration(hours: 9))), 2);
    expect(Tracker(minimumDay(sat)).streak(sun), 1);
  });

  test('week summary and audit verdict', () {
    final mon = DateTime(2026, 11, 2);
    final logs = [...minimumDay(mon), ...minimumDay(addDays(mon, 1))];
    final week = Tracker(logs).week(addDays(mon, 3));
    expect(week.start, mon);
    expect(week.closedDays, 3);
    expect(week.onTimeDays, 2);
    expect(week.verdict, contains('80%'));
    expect(Tracker([]).week(mon).rate, isNull);
  });

  test('report lists every task with marks and debt', () {
    final report = buildReport(Tracker(minimumDay(sat)), sat.add(const Duration(hours: 21)));
    expect(report, contains('✅ Bugun: 6/6'));
    expect(report, contains('Listening'));
    expect(report, contains('🔴 Qarz: 6 ta'));
  });

  testWidgets('home shows debt and red alarm, and logs a task', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = AppState();
    await tester.pumpWidget(HabitppApp(state: state, clock: () => DateTime(2026, 11, 1, 10)));

    expect(find.text('12 ta qarz'), findsOneWidget);
    expect(find.textContaining("2 KUN KETMA-KET"), findsOneWidget);

    await tester.tap(find.text('Writing').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '200');
    await tester.pump();
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(state.logs, hasLength(1));
    expect(state.logs.single.date, '2026-11-01');
    expect(find.text('1/6'), findsOneWidget);
  });
}

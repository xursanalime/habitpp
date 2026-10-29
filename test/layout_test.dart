import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitpp/logic.dart';
import 'package:habitpp/main.dart';
import 'package:habitpp/models.dart';
import 'package:habitpp/store.dart';

/// Renders every page at desktop, tablet and phone sizes with real-looking
/// data; any overflow or layout exception fails the test.
void main() {
  final now = DateTime(2026, 11, 4, 19);
  final logs = <LogEntry>[
    for (var i = 0; i < 6; i++) ...[
      LogEntry(
        date: dayKey(addDays(now, -i)),
        taskId: i.isEven ? 'reading' : 'listening',
        value: 8 + i,
        total: 14,
        note: i == 0 ? "TFNG'da adashdim" : '',
        loggedAt: addDays(now, -i),
      ),
      LogEntry(
        date: dayKey(addDays(now, -i)),
        taskId: 'vocab_new',
        value: 10 + i * 6,
        loggedAt: addDays(now, -i),
      ),
      LogEntry(date: dayKey(addDays(now, -i)), taskId: 'writing', value: 180, loggedAt: addDays(now, -i)),
    ],
  ];

  for (final size in const [Size(1360, 860), Size(900, 800), Size(400, 820)]) {
    for (final page in const ['Bugun', 'Statistika', 'Sozlamalar']) {
      testWidgets('$page at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          HabitppApp(
            state: AppState(logs: [...logs]),
            clock: () => now,
          ),
        );
        await tester.tap(find.text(page).last);
        await tester.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

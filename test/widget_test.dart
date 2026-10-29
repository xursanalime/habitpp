import 'package:flutter_test/flutter_test.dart';
import 'package:habitpp/main.dart';

void main() {
  test('daysUntilExam counts calendar days', () {
    expect(daysUntilExam(DateTime(2026, 10, 29, 23, 59)), 62);
    expect(daysUntilExam(DateTime(2026, 12, 30, 8)), 0);
    expect(daysUntilExam(DateTime(2027, 1, 5)), 0);
  });

  testWidgets('home screen shows greeting and countdown label', (tester) async {
    await tester.pumpWidget(const HabitppApp());
    expect(find.text('Salom, Xursanali'), findsOneWidget);
    expect(find.text('kun qoldi — IELTS 30-dekabr'), findsOneWidget);
  });
}

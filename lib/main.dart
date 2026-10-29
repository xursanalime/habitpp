import 'package:flutter/material.dart';

final DateTime examDate = DateTime(2026, 12, 30);

/// Whole days left until the exam, counted by calendar date (never negative).
int daysUntilExam(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final days = examDate.difference(today).inDays;
  return days < 0 ? 0 : days;
}

void main() {
  runApp(const HabitppApp());
}

class HabitppApp extends StatelessWidget {
  const HabitppApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitpp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = daysUntilExam(DateTime.now());
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Salom, Xursanali', style: text.headlineSmall),
            const SizedBox(height: 24),
            Text(
              '$days',
              style: text.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            Text('kun qoldi — IELTS 30-dekabr', style: text.titleMedium),
          ],
        ),
      ),
    );
  }
}

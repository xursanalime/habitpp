import 'models.dart';

final DateTime examDate = DateTime(2026, 12, 30);

/// First day missed tasks turn into debt.
final DateTime trackingStart = DateTime(2026, 10, 30);

const reading = TaskDef(
  id: 'reading',
  title: 'Reading',
  time: '07:00',
  metric: MetricKind.score,
  minimum: 13,
  full: 40,
  unit: 'savol',
);
const listening = TaskDef(
  id: 'listening',
  title: 'Listening',
  time: '07:00',
  metric: MetricKind.score,
  minimum: 10,
  full: 40,
  unit: 'savol',
);
const mock = TaskDef(
  id: 'mock',
  title: 'Haftalik mock (Reading yoki Listening)',
  time: '07:00',
  metric: MetricKind.score,
  minimum: 40,
  full: 80,
  unit: 'savol',
);
const writing = TaskDef(
  id: 'writing',
  title: 'Writing',
  time: '09:00',
  metric: MetricKind.amount,
  minimum: 150,
  full: 250,
  unit: "so'z",
);
const youtube = TaskDef(
  id: 'youtube',
  title: 'Inglizcha YouTube',
  time: '10:00',
  metric: MetricKind.amount,
  minimum: 10,
  full: 20,
  unit: 'daqiqa',
);
const speaking = TaskDef(
  id: 'speaking',
  title: 'Speaking',
  time: '11:00',
  metric: MetricKind.amount,
  minimum: 5,
  full: 15,
  unit: 'daqiqa',
);
const vocabNew = TaskDef(
  id: 'vocab_new',
  title: "Yangi so'zlar",
  time: '12:00',
  metric: MetricKind.amount,
  minimum: 10,
  full: 43,
  unit: "so'z",
);
const vocabReview = TaskDef(
  id: 'vocab_review',
  title: "So'z takrorlash",
  time: '14:00',
  metric: MetricKind.amount,
  minimum: 20,
  full: 60,
  unit: "so'z",
);

const allTasks = [
  reading,
  listening,
  mock,
  writing,
  youtube,
  speaking,
  vocabNew,
  vocabReview,
];

/// Reading Mon/Wed/Fri, Listening Tue/Thu/Sat, a mock on Sunday; the rest daily.
List<TaskDef> tasksFor(DateTime day) {
  final first = switch (day.weekday) {
    DateTime.monday || DateTime.wednesday || DateTime.friday => reading,
    DateTime.sunday => mock,
    _ => listening,
  };
  return [first, writing, youtube, speaking, vocabNew, vocabReview];
}

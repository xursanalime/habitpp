import 'package:flutter/material.dart';

import 'logic.dart';
import 'schedule.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.state, required this.now});

  final AppState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tracker = Tracker(state.logs);
    final week = tracker.week(now);
    final today = dateOnly(now);

    final panels = <Widget>[
      _WeekPanel(tracker: tracker, week: week, now: now),
      _HeatmapPanel(tracker: tracker, now: now),
      _AccuracyPanel(tracker: tracker),
      _VocabPanel(tracker: tracker, now: now),
      _TotalsPanel(week: week),
      _NotesPanel(state: state),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth >= 700 ? 32.0 : 16.0;
        final cols = box.maxWidth >= 1000 ? 2 : 1;
        const gap = 16.0;
        final inner = (box.maxWidth.clamp(0, 1240 + pad * 2) - pad * 2);
        final w = (inner - gap * (cols - 1)) / cols;
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hafta: ${shortDate(week.start)} — ${shortDate(addDays(week.start, 6))}',
                    style: const TextStyle(color: Palette.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Statistika',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [for (final p in panels) SizedBox(width: w, child: p)],
                  ),
                  if (today.isBefore(trackingStart)) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Statistika ${shortDate(trackingStart)} dan to'la boshlanadi.",
                      style: const TextStyle(color: Palette.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Color statusColor(DayStatus s) => switch (s) {
  DayStatus.onTime => Palette.success,
  DayStatus.late => Palette.warning,
  DayStatus.missed => Palette.danger,
  DayStatus.today => Palette.accent,
  DayStatus.future || DayStatus.beforeStart => Palette.surface2,
};

class _WeekPanel extends StatelessWidget {
  const _WeekPanel({required this.tracker, required this.week, required this.now});

  final Tracker tracker;
  final WeekSummary week;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final rate = week.rate;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('BU HAFTA · YAKSHANBA AUDITI'),
          Row(
            children: [
              ProgressRing(
                value: rate ?? 0,
                size: 110,
                stroke: 10,
                child: Text(
                  rate == null ? '—' : '${(rate * 100).round()}%',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${week.onTimeDays}/${week.closedDays} kun o'z vaqtida",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(week.verdict, style: const TextStyle(color: Palette.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: statusColor(tracker.status(addDays(week.start, i), now)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(weekdaysShort[i], style: const TextStyle(color: Palette.muted, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel({required this.tracker, required this.now});

  final Tracker tracker;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final first = addDays(weekStart(now), -21);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('OXIRGI 4 HAFTA'),
          for (var w = 0; w < 4; w++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      shortDate(addDays(first, w * 7)),
                      style: const TextStyle(color: Palette.muted, fontSize: 12),
                    ),
                  ),
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: statusColor(tracker.status(addDays(first, w * 7 + d), now)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(Palette.success, "O'z vaqtida"),
              _Legend(Palette.warning, 'Kechikib'),
              _Legend(Palette.danger, "O'tkazilgan"),
              _Legend(Palette.accent, 'Bugun'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Palette.muted, fontSize: 12)),
      ],
    );
  }
}

class _AccuracyPanel extends StatelessWidget {
  const _AccuracyPanel({required this.tracker});

  final Tracker tracker;

  @override
  Widget build(BuildContext context) {
    final entries = tracker.scoreEntries();
    final recent = entries.length > 20 ? entries.sublist(entries.length - 20) : entries;
    final values = [for (final e in recent) e.accuracy!];
    final avg = values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('READING · LISTENING · MOCK ANIQLIGI'),
          if (values.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  "Reading yoki Listening natijasini kiritsang, grafik shu yerda o'sadi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.muted),
                ),
              ),
            )
          else ...[
            LineChart(values: values, color: taskStyle['reading']!.$2),
            const SizedBox(height: 12),
            Text(
              'Oxirgi: ${(values.last * 100).round()}% · O\'rtacha: ${(avg! * 100).round()}% · ${values.length} ta natija',
              style: const TextStyle(color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _VocabPanel extends StatelessWidget {
  const _VocabPanel({required this.tracker, required this.now});

  final Tracker tracker;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const days = 14;
    final values = tracker.dailyTotals(vocabNew.id, now, days);
    final labels = [for (var i = days - 1; i >= 0; i--) '${addDays(dateOnly(now), -i).day}'];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("YANGI SO'ZLAR · 14 KUN"),
          BarChart(values: values, labels: labels, color: taskStyle[vocabNew.id]!.$2, target: vocabNew.full),
          const SizedBox(height: 12),
          Text(
            "Jami: ${values.fold(0, (a, b) => a + b)} so'z · punktir chiziq — kunlik to'liq maqsad (${vocabNew.full})",
            style: const TextStyle(color: Palette.muted),
          ),
        ],
      ),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    final rows = allTasks.where((t) => week.totals.containsKey(t.id)).toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('HAFTALIK HISOB · DUSHANBADAN 0 DAN'),
          for (final t in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(taskStyle[t.id]!.$1, color: taskStyle[t.id]!.$2, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.title)),
                  Text(
                    '${week.totals[t.id]}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 52,
                    child: Text(t.unit, style: const TextStyle(color: Palette.muted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final notes = state.logs.where((e) => e.note.isNotEmpty).toList().reversed.take(8).toList();
    final byId = {for (final t in allTasks) t.id: t};
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('OXIRGI IZOHLAR'),
          if (notes.isEmpty)
            const Text(
              "Natija kiritayotganda izoh yozsang (masalan, \"TFNG'da adashdim\"), shu yerda chiqadi.",
              style: TextStyle(color: Palette.muted, height: 1.4),
            ),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(taskStyle[n.taskId]?.$1 ?? Icons.notes, color: taskStyle[n.taskId]?.$2, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${byId[n.taskId]?.title ?? n.taskId} · ${n.date.substring(5)}  ',
                            style: const TextStyle(color: Palette.muted, fontSize: 12),
                          ),
                          TextSpan(text: n.note),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

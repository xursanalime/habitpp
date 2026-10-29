import 'dart:async';

import 'package:flutter/material.dart';

import 'logic.dart';
import 'models.dart';
import 'proof_dialog.dart';
import 'schedule.dart';
import 'store.dart';

const _months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyn', 'iyl', 'avg', 'sen', 'okt', 'noy', 'dek'];
const _weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

String shortDate(DateTime d) => '${d.day}-${_months[d.month - 1]}';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state, this.clock = DateTime.now});

  final AppState state;
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // Re-evaluate every minute so the day rolls over at midnight.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _log(TaskDef task, DateTime day, int progress) async {
    final entry = await showProofDialog(
      context,
      task: task,
      day: day,
      progress: progress,
      clock: widget.clock,
    );
    if (entry != null) await widget.state.add(entry);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final now = widget.clock();
        final today = dateOnly(now);
        final tracker = Tracker(widget.state.logs);
        final alarm = tracker.alarm(now);
        final debts = tracker.debts(now);
        final tasks = tasksFor(today);
        final done = tasks.where((t) => tracker.progress(today, t) >= t.minimum).length;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: alarm == Alarm.red ? const Color(0xFF3A0B0B) : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Header(now: now, streak: tracker.streak(now)),
                    const SizedBox(height: 12),
                    if (today.isBefore(trackingStart))
                      _Banner(
                        color: scheme.secondaryContainer,
                        text: 'Tizim ${shortDate(trackingStart)} dan boshlanadi. '
                            "Undan keyin bajarilmagan har bir vazifa qarzga yoziladi.",
                      )
                    else if (alarm == Alarm.red)
                      const _Banner(
                        color: Color(0xFFB71C1C),
                        text: "2 KUN KETMA-KET O'TKAZILDI.\n"
                            "Bugun hamma vazifani hech bo'lmasa minimal darajada bajar. "
                            '"Endi baribir" degan fikr — eng katta dushman.',
                      )
                    else if (alarm == Alarm.warning)
                      const _Banner(
                        color: Color(0xFFE65100),
                        text: "Kecha to'liq bajarilmadi. Bugun ham o'tkazsang — 2 kun bo'ladi.",
                      ),
                    const SizedBox(height: 12),
                    Text('Bugun · ${_weekdays[today.weekday - 1]} · $done/${tasks.length}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: done / tasks.length, minHeight: 8),
                    const SizedBox(height: 8),
                    for (final t in tasks)
                      _TaskTile(
                        task: t,
                        progress: tracker.progress(today, t),
                        leading: t.time,
                        onTap: () => _log(t, today, tracker.progress(today, t)),
                      ),
                    if (debts.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('QARZ: ${debts.length} ta',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (final d in debts)
                        _TaskTile(
                          task: d.task,
                          progress: d.progress,
                          leading: shortDate(d.date),
                          isDebt: true,
                          onTap: () => _log(d.task, d.date, d.progress),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now, required this.streak});

  final DateTime now;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text('${daysUntilExam(now)}',
                style: text.displayLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('kun qoldi', style: text.titleLarge),
                  Text('IELTS · 30-dekabr', style: text.bodyMedium),
                  const SizedBox(height: 6),
                  Text('🔥 $streak kun ketma-ket', style: text.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.progress,
    required this.leading,
    required this.onTap,
    this.isDebt = false,
  });

  final TaskDef task;
  final int progress;
  final String leading;
  final VoidCallback onTap;
  final bool isDebt;

  @override
  Widget build(BuildContext context) {
    final level = levelOf(task, progress);
    final (icon, color) = switch (level) {
      Level.full => (Icons.check_circle, Colors.greenAccent),
      Level.minimum => (Icons.check_circle_outline, Colors.lightGreen),
      Level.started => (Icons.timelapse, Colors.orangeAccent),
      Level.none => (Icons.radio_button_unchecked,
          isDebt ? Colors.redAccent : Colors.grey),
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(width: 56, child: Center(child: Text(leading))),
        title: Text(task.title),
        subtitle: Text('$progress / ${task.minimum} ${task.unit} · to\'liq ${task.full}'),
        trailing: Icon(icon, color: color),
      ),
    );
  }
}

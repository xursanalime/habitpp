import 'dart:async';

import 'package:flutter/material.dart';

import 'desktop.dart';
import 'logic.dart';
import 'models.dart';
import 'proof_dialog.dart';
import 'schedule.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'store.dart';
import 'theme.dart';
import 'today_page.dart';

/// App shell: sidebar on wide screens, bottom bar on narrow ones, plus the
/// once-a-day 20:45 reminder and 20:59 Telegram report.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state, this.clock = DateTime.now});

  final AppState state;
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _tick;
  int _page = 0;
  bool _reporting = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate every 30 s so the day rolls over and timed actions fire.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {});
      _runTimedActions();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTimedActions());
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _runTimedActions() async {
    final now = widget.clock();
    final key = dayKey(now);
    final minutes = now.hour * 60 + now.minute;
    final s = widget.state.settings;
    final tracker = Tracker(widget.state.logs);
    final today = dateOnly(now);

    if (s.remindAt2045 && minutes >= 20 * 60 + 45 && s.lastReminded != key) {
      await widget.state.updateSettings((s) => s.lastReminded = key);
      if (!tracker.completedOnTime(today)) {
        final tasks = tasksFor(today);
        final done = tasks.where((t) => tracker.progress(today, t) >= t.minimum).length;
        await notify(
          'Habitpp · 20:59 da hisobot',
          "Bugun $done/${tasks.length}. Qolganini minimal dozada bo'lsa ham yop.",
        );
      }
    }

    if (s.autoReport && s.telegramReady && minutes >= 20 * 60 + 59 && s.lastReported != key && !_reporting) {
      _reporting = true;
      final error = await sendTelegram(s.telegramToken, s.telegramChatId, buildReport(tracker, now));
      _reporting = false;
      if (error == null) {
        await widget.state.updateSettings((s) => s.lastReported = key);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
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
        final tracker = Tracker(widget.state.logs);
        final red = tracker.alarm(now) == Alarm.red;
        final page = switch (_page) {
          0 => TodayPage(state: widget.state, now: now, onLog: _log),
          1 => StatsPage(state: widget.state, now: now),
          _ => SettingsPage(state: widget.state),
        };
        final body = DecoratedBox(
          decoration: BoxDecoration(
            gradient: red
                ? const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.4,
                    colors: [Color(0xFF4A0E14), Palette.bg],
                  )
                : const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.4,
                    colors: [Color(0xFF1A1020), Palette.bg],
                  ),
          ),
          child: page,
        );

        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= 860) {
              return Scaffold(
                body: Row(
                  children: [
                    _Sidebar(
                      index: _page,
                      onSelect: (i) => setState(() => _page = i),
                      daysLeft: daysUntilExam(now),
                      debtCount: tracker.debts(now).length,
                    ),
                    const VerticalDivider(width: 1, color: Palette.border),
                    Expanded(child: body),
                  ],
                ),
              );
            }
            return Scaffold(
              body: SafeArea(child: body),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _page,
                onDestinationSelected: (i) => setState(() => _page = i),
                destinations: [
                  for (final d in _destinations) NavigationDestination(icon: Icon(d.$1), label: d.$2),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

const _destinations = [
  (Icons.today_rounded, 'Bugun'),
  (Icons.insights_rounded, 'Statistika'),
  (Icons.tune_rounded, 'Sozlamalar'),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.index,
    required this.onSelect,
    required this.daysLeft,
    required this.debtCount,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int daysLeft;
  final int debtCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Palette.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: Palette.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Habitpp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('IELTS rejimi', style: TextStyle(color: Palette.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < _destinations.length; i++)
            _NavItem(
              icon: _destinations[i].$1,
              label: _destinations[i].$2,
              selected: i == index,
              badge: i == 0 && debtCount > 0 ? '$debtCount' : null,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IMTIHONGACHA',
                  style: TextStyle(color: Palette.muted, fontSize: 11, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text('$daysLeft kun', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    // 72-day system: from 19-okt to 30-dek.
                    value: (1 - daysLeft / 72).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? Palette.accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? Palette.accent : Palette.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Palette.text : Palette.muted,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Palette.danger, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      badge!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

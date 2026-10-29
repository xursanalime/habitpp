import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'desktop.dart';
import 'logic.dart';
import 'models.dart';
import 'schedule.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

typedef LogTask = Future<void> Function(TaskDef task, DateTime day, int progress);

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.state, required this.now, required this.onLog});

  final AppState state;
  final DateTime now;
  final LogTask onLog;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(now);
    final tracker = Tracker(state.logs);
    final tasks = tasksFor(today);
    final done = tasks.where((t) => tracker.progress(today, t) >= t.minimum).length;
    final debts = tracker.debts(now);
    final alarm = tracker.alarm(now);
    final week = tracker.week(now);

    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth >= 700 ? 32.0 : 16.0;
        final twoCol = box.maxWidth >= 1150;
        final side = [
          _DebtPanel(debts: debts, onLog: onLog),
          const SizedBox(height: 16),
          _ReportPanel(state: state, report: buildReport(tracker, now)),
        ];
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${weekdays[today.weekday - 1]}, ${shortDate(today)}',
                    style: const TextStyle(color: Palette.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm == Alarm.red ? 'Bugun qaytish kuni.' : "Ishla. Bahona yo'q.",
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
                  _Hero(
                    now: now,
                    done: done,
                    total: tasks.length,
                    streak: tracker.streak(now),
                    debtCount: debts.length,
                    weekRate: week.rate,
                  ),
                  const SizedBox(height: 16),
                  if (today.isBefore(trackingStart))
                    _Banner(
                      color: Palette.accent2,
                      icon: Icons.flag_rounded,
                      title: 'Tizim ${shortDate(trackingStart)} dan boshlanadi',
                      text:
                          "Undan keyin bajarilmagan har bir vazifa qarzga yoziladi. Bugun mashq qilib ko'r.",
                    )
                  else if (alarm == Alarm.red)
                    const _Banner(
                      color: Palette.danger,
                      icon: Icons.warning_rounded,
                      title: "2 KUN KETMA-KET O'TKAZILDI",
                      text:
                          "Bugun hamma vazifani hech bo'lmasa minimal darajada bajar. "
                          '"Endi baribir" degan fikr — eng katta dushman.',
                    )
                  else if (alarm == Alarm.warning)
                    const _Banner(
                      color: Palette.warning,
                      icon: Icons.error_outline_rounded,
                      title: "Kecha to'liq bajarilmadi",
                      text: "Bugun ham o'tkazsang — 2 kun bo'ladi. Minimal doza ham hisob.",
                    ),
                  const SizedBox(height: 24),
                  if (twoCol)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TaskGrid(tasks: tasks, tracker: tracker, day: today, onLog: onLog),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(width: 380, child: Column(children: side)),
                      ],
                    )
                  else ...[
                    _TaskGrid(tasks: tasks, tracker: tracker, day: today, onLog: onLog),
                    const SizedBox(height: 20),
                    ...side,
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.now,
    required this.done,
    required this.total,
    required this.streak,
    required this.debtCount,
    required this.weekRate,
  });

  final DateTime now;
  final int done;
  final int total;
  final int streak;
  final int debtCount;
  final double? weekRate;

  @override
  Widget build(BuildContext context) {
    final days = daysUntilExam(now);
    return Panel(
      padding: const EdgeInsets.all(24),
      gradient: LinearGradient(
        colors: [Palette.accent.withValues(alpha: 0.18), Palette.surface, Palette.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IMTIHONGACHA',
                style: TextStyle(
                  color: Palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              ShaderMask(
                shaderCallback: (r) => Palette.accentGradient.createShader(r),
                child: Text(
                  '$days',
                  style: const TextStyle(
                    fontSize: 84,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3,
                  ),
                ),
              ),
              const Text(
                'kun · IELTS 30-dekabr',
                style: TextStyle(color: Palette.text, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          ProgressRing(
            value: done / total,
            size: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$done/$total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('bugun', style: TextStyle(color: Palette.muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Stat(
                icon: Icons.local_fire_department_rounded,
                color: Palette.accent2,
                label: 'ketma-ket',
                value: '$streak kun',
              ),
              const SizedBox(height: 12),
              _Stat(
                icon: Icons.receipt_long_rounded,
                color: debtCount > 0 ? Palette.danger : Palette.success,
                label: 'qarz',
                value: '$debtCount ta',
              ),
              const SizedBox(height: 12),
              _Stat(
                icon: Icons.insights_rounded,
                color: Palette.minimum,
                label: 'bu hafta',
                value: weekRate == null ? '—' : '${(weekRate! * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Palette.muted)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.title, required this.text});

  final Color color;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Palette.text, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskGrid extends StatelessWidget {
  const _TaskGrid({required this.tasks, required this.tracker, required this.day, required this.onLog});

  final List<TaskDef> tasks;
  final Tracker tracker;
  final DateTime day;
  final LogTask onLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('BUGUNGI VAZIFALAR'),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 620 ? 2 : 1;
            const gap = 14.0;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in tasks)
                  SizedBox(
                    width: w,
                    child: TaskCard(
                      task: t,
                      progress: tracker.progress(day, t),
                      onTap: () => onLog(t, day, tracker.progress(day, t)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.progress, required this.onTap});

  final TaskDef task;
  final int progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = taskStyle[task.id]!;
    final level = levelOf(task, progress);
    final (label, labelColor) = switch (level) {
      Level.full => ("To'liq ✓✓", Palette.success),
      Level.minimum => ('Minimal ✓', Palette.minimum),
      Level.started => ('Jarayonda', Palette.warning),
      Level.none => ('Boshlanmagan', Palette.muted),
    };
    final fraction = (progress / task.full).clamp(0.0, 1.0);
    final minAt = task.minimum / task.full;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Panel(
          padding: const EdgeInsets.all(18),
          borderColor: level == Level.full ? Palette.success.withValues(alpha: 0.4) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${task.time} · minimum ${task.minimum} ${task.unit}',
                          style: const TextStyle(color: Palette.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Pill(label, color: labelColor),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, box) {
                  return SizedBox(
                    height: 10,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Container(
                          width: box.maxWidth * fraction,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Positioned(
                          left: box.maxWidth * minAt - 1,
                          top: -3,
                          bottom: -3,
                          child: Container(width: 2, color: Palette.text.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('$progress', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Flexible(
                    child: Text(
                      ' / ${task.full} ${task.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Palette.muted),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.add_circle_rounded, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Kiritish',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtPanel extends StatelessWidget {
  const _DebtPanel({required this.debts, required this.onLog});

  final List<Debt> debts;
  final LogTask onLog;

  @override
  Widget build(BuildContext context) {
    final has = debts.isNotEmpty;
    return Panel(
      borderColor: has ? Palette.danger.withValues(alpha: 0.5) : null,
      gradient: has
          ? LinearGradient(
              colors: [Palette.danger.withValues(alpha: 0.14), Palette.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                has ? Icons.receipt_long_rounded : Icons.verified_rounded,
                color: has ? Palette.danger : Palette.success,
              ),
              const SizedBox(width: 10),
              Text(
                has ? '${debts.length} ta qarz' : "Qarz yo'q",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: has ? Palette.danger : Palette.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            has
                ? "Bosib, kechikib bo'lsa ham bajar. Qarz o'chadi, lekin kun \"o'z vaqtida\" bo'lmaydi."
                : 'Shunday davom et. Har bir kun — alohida g\'alaba.',
            style: const TextStyle(color: Palette.muted, height: 1.4),
          ),
          if (has) const SizedBox(height: 12),
          for (final d in debts.take(12)) _DebtRow(debt: d, onTap: () => onLog(d.task, d.date, d.progress)),
          if (debts.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('va yana ${debts.length - 12} ta…', style: const TextStyle(color: Palette.muted)),
            ),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.debt, required this.onTap});

  final Debt debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = taskStyle[debt.task.id]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(shortDate(debt.date), style: const TextStyle(color: Palette.muted)),
            ),
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(debt.task.title, overflow: TextOverflow.ellipsis)),
            Text(
              '${debt.progress}/${debt.task.minimum}',
              style: const TextStyle(color: Palette.danger, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPanel extends StatefulWidget {
  const _ReportPanel({required this.state, required this.report});

  final AppState state;
  final String report;

  @override
  State<_ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<_ReportPanel> {
  bool _sending = false;

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send() async {
    final s = widget.state.settings;
    setState(() => _sending = true);
    final error = await sendTelegram(s.telegramToken, s.telegramChatId, widget.report);
    if (!mounted) return;
    setState(() => _sending = false);
    _toast(error ?? 'Hisobot Telegramga yuborildi ✅');
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.state.settings.telegramReady;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('KUNLIK HISOBOT · 20:59'),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(widget.report, style: const TextStyle(height: 1.5, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.report));
                    _toast("Nusxa olindi — Claude'ga joylashtiring");
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Nusxa'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: ready && !_sending ? _send : null,
                  icon: _sending
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Telegram'),
                ),
              ),
            ],
          ),
          if (!ready)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Telegram uchun Sozlamalarda bot tokenini kiriting.',
                style: TextStyle(color: Palette.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

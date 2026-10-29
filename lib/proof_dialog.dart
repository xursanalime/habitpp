import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart';
import 'models.dart';
import 'theme.dart';

/// Asks for the result of a task; returns null if cancelled.
Future<LogEntry?> showProofDialog(
  BuildContext context, {
  required TaskDef task,
  required DateTime day,
  required int progress,
  required DateTime Function() clock,
}) {
  return showDialog<LogEntry>(
    context: context,
    builder: (_) => _ProofDialog(task: task, day: day, progress: progress, clock: clock),
  );
}

class _ProofDialog extends StatefulWidget {
  const _ProofDialog({required this.task, required this.day, required this.progress, required this.clock});

  final TaskDef task;
  final DateTime day;
  final int progress;
  final DateTime Function() clock;

  @override
  State<_ProofDialog> createState() => _ProofDialogState();
}

class _ProofDialogState extends State<_ProofDialog> {
  final _value = TextEditingController();
  final _total = TextEditingController();
  final _note = TextEditingController();

  bool get _isScore => widget.task.metric == MetricKind.score;

  int? get _valueNum => int.tryParse(_value.text);
  int? get _totalNum => int.tryParse(_total.text);

  String? get _error {
    final v = _valueNum;
    if (v == null) return null;
    if (!_isScore) return v <= 0 ? "0 dan katta bo'lsin" : null;
    final t = _totalNum;
    if (t == null) return null;
    if (t <= 0) return "Savollar soni 0 dan katta bo'lsin";
    if (v > t) return "To'g'ri javoblar jami savoldan ko'p bo'lmaydi";
    return null;
  }

  bool get _valid => _valueNum != null && (!_isScore || _totalNum != null) && _error == null;

  @override
  void dispose() {
    _value.dispose();
    _total.dispose();
    _note.dispose();
    super.dispose();
  }

  Widget _numberField(TextEditingController c, String label, {bool autofocus = false}) {
    return TextField(
      controller: c,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final (icon, color) = taskStyle[t.id]!;
    final late = dayKey(widget.day) != dayKey(widget.clock());
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hozir: ${widget.progress} ${t.unit} · minimum ${t.minimum} · to\'liq ${t.full}',
                style: const TextStyle(color: Palette.muted),
              ),
              if (late)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Qarz to\'lash: ${widget.day.day}-sana uchun yoziladi (kechikkan).',
                    style: const TextStyle(color: Palette.warning),
                  ),
                ),
              const SizedBox(height: 16),
              if (_isScore) ...[
                _numberField(_value, "To'g'ri javoblar", autofocus: true),
                _numberField(_total, 'Jami savollar'),
              ] else
                _numberField(_value, 'Qancha (${t.unit})', autofocus: true),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(
                  context,
                  LogEntry(
                    date: dayKey(widget.day),
                    taskId: t.id,
                    value: _valueNum!,
                    total: _isScore ? _totalNum : null,
                    note: _note.text.trim(),
                    loggedAt: widget.clock(),
                  ),
                )
              : null,
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}

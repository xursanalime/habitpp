import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

const months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyn', 'iyl', 'avg', 'sen', 'okt', 'noy', 'dek'];
const weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
const weekdaysShort = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

String shortDate(DateTime d) => '${d.day}-${months[d.month - 1]}';

/// Rounded surface card used everywhere.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    // Ink paints on a Material so ListTiles and ripples inside stay visible.
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? Palette.surface : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor ?? Palette.border),
        ),
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Palette.muted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)],
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Circular progress with a gradient arc.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.size,
    this.stroke = 12,
    required this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1), stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke);

  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    if (value <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Palette.accent, Palette.accent2, Palette.accent],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.stroke != stroke;
}

/// Simple line chart for values in 0..1, with 25/50/75% guides.
class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.values, required this.color, this.height = 180});

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(values, color)),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    final chart = Rect.fromLTWH(left, 8, size.width - left - 8, size.height - 16);
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (final g in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = chart.bottom - chart.height * g;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), guide);
      final tp = TextPainter(
        text: TextSpan(
          text: '${(g * 100).round()}%',
          style: const TextStyle(color: Palette.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    if (values.isEmpty) return;

    Offset at(int i) => Offset(
      values.length == 1 ? chart.center.dx : chart.left + chart.width * i / (values.length - 1),
      chart.bottom - chart.height * values[i].clamp(0, 1),
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(path)
      ..lineTo(at(values.length - 1).dx, chart.bottom)
      ..lineTo(at(0).dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.color != color;
}

/// Bar chart with an optional dashed target line.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.target,
    this.height = 180,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;
  final int? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BarPainter(values, labels, color, target)),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.values, this.labels, this.color, this.target);

  final List<int> values;
  final List<String> labels;
  final Color color;
  final int? target;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(0, 8, size.width, size.height - 30);
    final top = [...values, target ?? 0, 1].reduce(math.max).toDouble();
    final slot = chart.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = chart.height * values[i] / top;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(chart.left + slot * i + slot * 0.2, chart.bottom - h, slot * 0.6, h),
        const Radius.circular(6),
      );
      final hit = target != null && values[i] >= target!;
      canvas.drawRRect(
        r,
        Paint()
          ..color = values[i] == 0
              ? Colors.white.withValues(alpha: 0.06)
              : (hit ? color : color.withValues(alpha: 0.45)),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Palette.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chart.left + slot * i + (slot - tp.width) / 2, chart.bottom + 8));
    }
    if (target != null) {
      final y = chart.bottom - chart.height * target! / top;
      final p = Paint()
        ..color = Palette.text.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      for (var x = chart.left; x < chart.right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, chart.right), y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}

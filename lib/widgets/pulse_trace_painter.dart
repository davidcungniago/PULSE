import 'dart:math';
import 'package:flutter/material.dart';
import '../models/waveform.dart';
import '../theme/pulse_colors.dart';

class PulseTracePainter extends CustomPainter {
  PulseTracePainter(
      {required this.waveform,
      required this.colors,
      required this.traceColor,
      this.sweep,
      this.textDirection = TextDirection.ltr})
      : super(repaint: sweep);

  final Waveform waveform;
  final PulseColors colors;
  final Color traceColor;
  final Animation<double>? sweep;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surfaceTrace);
    final grid = Paint()..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 12) {
      grid.color = x % 60 == 0 ? colors.gridMajor : colors.gridMinor;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 12) {
      grid.color = y % 60 == 0 ? colors.gridMajor : colors.gridMinor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (waveform.points.isEmpty) return;
    final stroke = Paint()
      ..color = traceColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (waveform.isFlat) {
      final y = waveform.points.first.dy;
      for (var x = 0.0; x < size.width; x += 12) {
        canvas.drawLine(
            Offset(x, y), Offset(min(x + 6, size.width), y), stroke);
      }
      final label = TextPainter(
        text: TextSpan(
            text: 'Tanpa sinyal',
            style: TextStyle(color: colors.textMuted, fontSize: 11)),
        textDirection: textDirection,
      )..layout(maxWidth: size.width);
      label.paint(canvas, const Offset(8, 8));
      return;
    }
    final headX = sweep == null ? null : sweep!.value * size.width;
    bool hidden(double x) =>
        headX != null && (x - headX + size.width) % size.width < 26;
    var path = Path();
    Color? currentColor;
    var connected = false;
    for (final point in waveform.points) {
      final drift = waveform.ectopicXs
          .any((x) => point.dx >= x - 12 && point.dx <= x + 44);
      final color = drift ? colors.drift : traceColor;
      if (hidden(point.dx)) {
        if (currentColor != null) {
          canvas.drawPath(path, stroke..color = currentColor);
        }
        path = Path();
        connected = false;
        currentColor = null;
        continue;
      }
      if (currentColor != color) {
        if (currentColor != null) {
          canvas.drawPath(path, stroke..color = currentColor);
        }
        path = Path();
        connected = false;
        currentColor = color;
      }
      if (connected) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
        connected = true;
      }
    }
    if (currentColor != null) {
      canvas.drawPath(path, stroke..color = currentColor);
    }
    for (final x in waveform.ectopicXs) {
      if (hidden(x)) continue;
      final y = max(
          8.0,
          waveform.points[x.floor().clamp(0, waveform.points.length - 1)].dy -
              8);
      final marker = Path()
        ..moveTo(x, y)
        ..lineTo(x - 4, y - 6)
        ..lineTo(x + 4, y - 6)
        ..close();
      canvas.drawPath(marker, Paint()..color = colors.drift);
    }
    if (headX != null) {
      final point =
          waveform.points[headX.floor().clamp(0, waveform.points.length - 1)];
      canvas.drawCircle(point, 3, Paint()..color = traceColor);
    }
  }

  @override
  bool shouldRepaint(PulseTracePainter oldDelegate) =>
      waveform != oldDelegate.waveform ||
      colors.brightness != oldDelegate.colors.brightness ||
      traceColor != oldDelegate.traceColor ||
      sweep != oldDelegate.sweep ||
      textDirection != oldDelegate.textDirection;
}

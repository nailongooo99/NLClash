import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiquidHighlightPainter extends CustomPainter {
  final double progress;
  final Offset position;
  final Color color;
  final double intensity;

  const LiquidHighlightPainter({
    required this.progress,
    required this.position,
    required this.color,
    this.intensity = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = color.withValues(alpha: 0.08 * progress),
    );
    final radius = size.shortestSide * 1.5;
    final alignment = Alignment(
      (position.dx / size.width) * 2 - 1,
      (position.dy / size.height) * 2 - 1,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: alignment,
        radius: radius,
        colors: [
          color.withValues(alpha: intensity * progress),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidHighlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.position != position ||
        oldDelegate.color != color ||
        oldDelegate.intensity != intensity;
  }
}

double liquidTanh(double value) {
  final exp2x = math.exp(2 * value);
  return (exp2x - 1) / (exp2x + 1);
}

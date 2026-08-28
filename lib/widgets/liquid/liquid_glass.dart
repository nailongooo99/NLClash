import 'dart:ui' as ui;

import 'package:flutter/material.dart';

List<double> _saturationMatrix(double saturation) {
  const rw = 0.2126;
  const gw = 0.7152;
  const bw = 0.0722;
  final r = (1 - saturation) * rw;
  final g = (1 - saturation) * gw;
  final b = (1 - saturation) * bw;
  return [
    r + saturation, g, b, 0, 0,
    r, g + saturation, b, 0, 0,
    r, g, b + saturation, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final ShapeBorder? shape;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color tint;
  final double tintOpacity;
  final bool enableHighlight;
  final double highlightWidth;
  final double highlightIntensity;
  final bool enableInnerShadow;
  final double innerShadowRadius;
  final double innerShadowIntensity;
  final List<BoxShadow> shadows;
  final double saturation;
  final double lensScale;
  final Offset? lensFocal;
  final EdgeInsetsGeometry padding;
  final StackFit fit;

  const LiquidGlass({
    super.key,
    required this.child,
    this.shape,
    this.borderRadius,
    this.blurSigma = 12,
    required this.tint,
    this.tintOpacity = 0.42,
    this.enableHighlight = true,
    this.highlightWidth = 1.2,
    this.highlightIntensity = 0.5,
    this.enableInnerShadow = true,
    this.innerShadowRadius = 5,
    this.innerShadowIntensity = 0.16,
    this.shadows = const [],
    this.saturation = 1.12,
    this.lensScale = 1,
    this.lensFocal,
    this.padding = EdgeInsets.zero,
    this.fit = StackFit.expand,
  });

  ShapeBorder get _shape {
    return shape ??
        RoundedSuperellipseBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(24),
        );
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark ? Colors.black : Colors.black54;
    final highlightColor = isDark
        ? Colors.white
        : Colors.white;
    final filter = blurSigma > 0
        ? ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma)
        : null;
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: shadows),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
              return ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: child,
              );
            }
            final focal = lensFocal ?? size.center(Offset.zero);
            Widget backdrop = ColoredBox(color: tint.withValues(alpha: tintOpacity));
            if (filter != null) {
              backdrop = BackdropFilter(filter: filter, child: backdrop);
            }
            if (saturation != 1) {
              backdrop = ColorFiltered(
                colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
                child: backdrop,
              );
            }
            if (lensScale != 1) {
              backdrop = Transform(
                transform: Matrix4.identity()
                  ..translateByDouble(focal.dx, focal.dy, 0, 1)
                  ..scaleByDouble(lensScale, lensScale, 1, 1)
                  ..translateByDouble(-focal.dx, -focal.dy, 0, 1),
                child: backdrop,
              );
            }
            return Stack(
              fit: fit,
              children: [
                Positioned.fill(child: backdrop),
                if (enableHighlight)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiquidHighlightPainter(
                        shape: shape,
                        color: highlightColor,
                        width: highlightWidth,
                        intensity: highlightIntensity,
                      ),
                    ),
                  ),
                if (enableInnerShadow)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiquidInnerShadowPainter(
                        shape: shape,
                        color: shadowColor,
                        radius: innerShadowRadius,
                        intensity: innerShadowIntensity,
                      ),
                    ),
                  ),
                Padding(padding: padding, child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiquidHighlightPainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;
  final double width;
  final double intensity;

  const _LiquidHighlightPainter({
    required this.shape,
    required this.color,
    required this.width,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    canvas.save();
    canvas.clipPath(path);
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: intensity),
          color.withValues(alpha: intensity * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, topPaint);
    final edgePaint = Paint()
      ..color = color.withValues(alpha: intensity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawPath(path, edgePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidHighlightPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.intensity != intensity;
  }
}

class _LiquidInnerShadowPainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;
  final double radius;
  final double intensity;

  const _LiquidInnerShadowPainter({
    required this.shape,
    required this.color,
    required this.radius,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    canvas.save();
    canvas.clipPath(path);
    final paint = Paint()
      ..color = color.withValues(alpha: intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidInnerShadowPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.intensity != intensity;
  }
}

import 'package:flutter/material.dart';

class LiquidWallpaper extends StatelessWidget {
  final Widget child;

  const LiquidWallpaper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLow,
            isDark
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.primaryContainer.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _WallpaperBlobPainter(
              primary: colorScheme.primary,
              secondary: colorScheme.secondary,
              tertiary: colorScheme.tertiary,
              isDark: isDark,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _WallpaperBlobPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final bool isDark;

  const _WallpaperBlobPainter({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <(Offset, double, Color)>[
      (
        Offset(size.width * 0.08, size.height * 0.12),
        size.shortestSide * 0.55,
        primary,
      ),
      (
        Offset(size.width * 0.92, size.height * 0.28),
        size.shortestSide * 0.45,
        secondary,
      ),
      (
        Offset(size.width * 0.5, size.height * 0.96),
        size.shortestSide * 0.5,
        tertiary,
      ),
    ];
    final alpha = isDark ? 0.16 : 0.2;
    for (final (center, radius, color) in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (center.dx / size.width) * 2 - 1,
            (center.dy / size.height) * 2 - 1,
          ),
          radius: 1,
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.35),
            color.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperBlobPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.tertiary != tertiary ||
        oldDelegate.isDark != isDark;
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? tint;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? scheme.surface).withValues(alpha: 0.58),
            borderRadius: borderRadius,
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.onSurface.withValues(alpha: 0.18),
                Colors.transparent,
                scheme.primary.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class LiquidGlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const LiquidGlassToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? scheme.primary.withValues(alpha: 0.72)
                : scheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.2)),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: value ? 0.95 : 0.82),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassNavigationBar extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const LiquidGlassNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<LiquidGlassNavigationBar> createState() =>
      _LiquidGlassNavigationBarState();
}

class _LiquidGlassNavigationBarState extends State<LiquidGlassNavigationBar> {
  double _drag = 0;
  bool _pressed = false;

  void _finishDrag() {
    if (_drag.abs() > 12) {
      final next = (widget.selectedIndex + (_drag > 0 ? 1 : -1)).clamp(
        0,
        widget.destinations.length - 1,
      ).toInt();
      widget.onDestinationSelected(next);
    }
    setState(() {
      _drag = 0;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _pressed = true),
      onHorizontalDragUpdate: (details) =>
          setState(() => _drag += details.delta.dx),
      onHorizontalDragEnd: (_) => _finishDrag(),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 1.025 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: LiquidGlassSurface(
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 68,
            selectedIndex: widget.selectedIndex,
            destinations: widget.destinations,
            onDestinationSelected: widget.onDestinationSelected,
          ),
        ),
      ),
    );
  }
}

import 'package:fl_clash/widgets/liquid/liquid_drag.dart';
import 'package:fl_clash/widgets/liquid/liquid_glass.dart';
import 'package:flutter/material.dart';

class LiquidSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? trackColor;
  final double? width;

  const LiquidSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
    this.width,
  });

  @override
  State<LiquidSwitch> createState() => _LiquidSwitchState();
}

class _LiquidSwitchState extends State<LiquidSwitch>
    with TickerProviderStateMixin {
  static const double _trackHeight = 28;
  static const double _thumbDiameter = 24;
  static const double _dragWidth = 20;
  static const double _padding = 2;

  late final LiquidDragController _controller;
  bool _didDrag = false;

  @override
  void initState() {
    super.initState();
    _controller = LiquidDragController(
      vsync: this,
      initialValue: widget.value ? 1 : 0,
      valueRange: const LiquidValueRange(0, 1),
      pressedScale: 1.5,
    );
  }

  @override
  void didUpdateWidget(covariant LiquidSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.animateToValue(widget.value ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(bool selected) {
    widget.onChanged?.call(selected);
  }

  void _handleDragStart(DragStartDetails details) {
    _didDrag = false;
    _controller.press();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (!_didDrag && dx != 0) {
      _didDrag = true;
    }
    _controller.updateValue(_controller.value + dx / _dragWidth);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_didDrag) {
      final selected = _controller.value >= 0.5;
      _controller.animateToValue(selected ? 1 : 0);
      _select(selected);
    } else {
      final selected = !widget.value;
      _controller.animateToValue(selected ? 1 : 0);
      _select(selected);
    }
    _didDrag = false;
    _controller.release();
  }

  void _handleTap() {
    final selected = !widget.value;
    _controller.animateToValue(selected ? 1 : 0);
    _select(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.activeColor ??
        (isDark ? const Color(0xFF30D158) : const Color(0xFF34C759));
    final track = widget.trackColor ??
        (isDark
            ? const Color(0xFF787880).withValues(alpha: 0.36)
            : const Color(0xFF787878).withValues(alpha: 0.2));
    final width = widget.width ?? 64;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onChanged == null ? null : _handleTap,
      onHorizontalDragStart: widget.onChanged == null
          ? null
          : _handleDragStart,
      onHorizontalDragUpdate: widget.onChanged == null
          ? null
          : _handleDragUpdate,
      onHorizontalDragEnd: widget.onChanged == null ? null : _handleDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final fraction = _controller.value;
          final progress = _controller.pressProgress;
          final trackColor = Color.lerp(track, accent, fraction)!;
          final thumbX = _padding + _dragWidth * fraction;
          final velocity = _controller.velocity;
          final scaleX =
              _controller.scaleX /
              (1 - (velocity * 0.75).clamp(-0.2, 0.2).toDouble());
          final scaleY =
              _controller.scaleY *
              (1 - (velocity * 0.25).clamp(-0.2, 0.2).toDouble());
          return SizedBox(
            width: width,
            height: _trackHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LiquidGlass(
                    shape: const StadiumBorder(),
                    blurSigma: 1,
                    tint: trackColor,
                    tintOpacity: 0.85,
                    enableHighlight: false,
                    enableInnerShadow: false,
                    child: const SizedBox(),
                  ),
                ),
                Positioned(
                  left: thumbX,
                  top: _padding,
                  width: _thumbDiameter,
                  height: _thumbDiameter,
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    child: LiquidGlass(
                      shape: const StadiumBorder(),
                      blurSigma: 8 * (1 - progress),
                      tint: Colors.white,
                      tintOpacity: 1 - progress,
                      enableHighlight: false,
                      enableInnerShadow: progress > 0,
                      innerShadowRadius: 4 * progress,
                      innerShadowIntensity: 0.12 * progress,
                      shadows: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                      lensScale: 1 + progress * 0.05,
                      child: const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

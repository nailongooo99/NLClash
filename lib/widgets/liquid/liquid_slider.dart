import 'package:fl_clash/widgets/liquid/liquid_drag.dart';
import 'package:fl_clash/widgets/liquid/liquid_glass.dart';
import 'package:flutter/material.dart';

class LiquidSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final int? divisions;
  final Color? activeColor;
  final Color? trackColor;

  const LiquidSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.onChanged,
    this.divisions,
    this.activeColor,
    this.trackColor,
  });

  @override
  State<LiquidSlider> createState() => _LiquidSliderState();
}

class _LiquidSliderState extends State<LiquidSlider>
    with TickerProviderStateMixin {
  static const double _trackHeight = 6;
  static const double _thumbDiameter = 24;

  late final LiquidDragController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LiquidDragController(
      vsync: this,
      initialValue: widget.value.clamp(widget.min, widget.max).toDouble(),
      valueRange: LiquidValueRange(widget.min, widget.max),
      pressedScale: 1.5,
    );
  }

  @override
  void didUpdateWidget(covariant LiquidSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.updateValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _controller.press();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final span = widget.max - widget.min;
    _controller.updateValue(
      (_controller.value + details.delta.dx / _trackWidth * span)
          .clamp(widget.min, widget.max)
          .toDouble(),
    );
    widget.onChanged?.call(_controller.value);
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller.release();
  }

  void _handleTapDown(TapDownDetails details) {
    final span = widget.max - widget.min;
    final target = (widget.min + details.localPosition.dx / _trackWidth * span)
        .clamp(widget.min, widget.max)
        .toDouble();
    _controller.animateToValue(target);
    widget.onChanged?.call(target);
  }

  double _trackWidth = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.activeColor ??
        (isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF));
    final track = widget.trackColor ??
        (isDark
            ? const Color(0xFF787880).withValues(alpha: 0.36)
            : const Color(0xFF787878).withValues(alpha: 0.2));
    return LayoutBuilder(
      builder: (context, constraints) {
        _trackWidth = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onChanged == null ? null : _handleTapDown,
          onHorizontalDragStart: widget.onChanged == null
              ? null
              : _handleDragStart,
          onHorizontalDragUpdate: widget.onChanged == null
              ? null
              : _handleDragUpdate,
          onHorizontalDragEnd: widget.onChanged == null
              ? null
              : _handleDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.progress;
              final pressProgress = _controller.pressProgress;
              final velocity = _controller.velocity;
              final scaleX =
                  _controller.scaleX /
                  (1 - (velocity * 0.75).clamp(-0.2, 0.2).toDouble());
              final scaleY =
                  _controller.scaleY *
                  (1 - (velocity * 0.25).clamp(-0.2, 0.2).toDouble());
              final thumbX = (progress * _trackWidth - _thumbDiameter / 2)
                  .clamp(
                    -_thumbDiameter / 4,
                    _trackWidth - _thumbDiameter * 3 / 4,
                  )
                  .toDouble();
              return SizedBox(
                height: _thumbDiameter,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (_thumbDiameter - _trackHeight) / 2,
                      height: _trackHeight,
                      child: ClipPath(
                        clipper: const ShapeBorderClipper(
                          shape: StadiumBorder(),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: track),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: ColoredBox(color: accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbX,
                      top: 0,
                      width: _thumbDiameter,
                      height: _thumbDiameter,
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: LiquidGlass(
                          shape: const StadiumBorder(),
                          blurSigma: 8 * (1 - pressProgress),
                          tint: Colors.white,
                          tintOpacity: 1 - pressProgress,
                          enableHighlight: false,
                          enableInnerShadow: pressProgress > 0,
                          innerShadowRadius: 4 * pressProgress,
                          innerShadowIntensity: 0.12 * pressProgress,
                          shadows: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                          lensScale: 1 + pressProgress * 0.06,
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
      },
    );
  }
}

import 'package:fl_clash/widgets/liquid/liquid_drag.dart';
import 'package:fl_clash/widgets/liquid/liquid_glass.dart';
import 'package:fl_clash/widgets/liquid/liquid_highlight.dart';
import 'package:flutter/material.dart';

class LiquidButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? tint;
  final Color? surfaceColor;
  final double height;
  final EdgeInsetsGeometry padding;

  const LiquidButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tint,
    this.surfaceColor,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late final LiquidHighlightController _highlight;

  @override
  void initState() {
    super.initState();
    _highlight = LiquidHighlightController(vsync: this);
  }

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _highlight.onDown(details.localPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _highlight.onUp();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _highlight.onUp();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onPressed == null ? null : _handleTapDown,
      onTapUp: widget.onPressed == null ? null : _handleTapUp,
      onTapCancel: widget.onPressed == null ? null : _handleTapCancel,
      child: AnimatedBuilder(
        animation: _highlight,
        builder: (context, _) {
          final progress = _highlight.pressProgress;
          final offset = _highlight.offset;
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final maxOffset = size.shortestSide;
              final scale = 1 + 4 / widget.height * progress;
              final tx = maxOffset * liquidTanh(0.05 * offset.dx / maxOffset);
              final ty = maxOffset * liquidTanh(0.05 * offset.dy / maxOffset);
              return Transform(
                transform: Matrix4.identity()
                  ..translateByDouble(tx, ty, 0, 1)
                  ..scaleByDouble(scale, scale, 1, 1),
                alignment: Alignment.center,
                child: LiquidGlass(
                  shape: const StadiumBorder(),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  blurSigma: 2,
                  lensHeight: 12,
                  lensAmount: 24,
                  saturation: 1.5,
                  tint: Colors.white,
                  tintOpacity: 0.06,
                  highlight: null,
                  enableInnerShadow: false,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LiquidHighlightPainter(
                            progress: progress,
                            position: _highlight.position,
                            color: Colors.white,
                            intensity: 0.12,
                          ),
                        ),
                      ),
                      if (widget.tint != null)
                        Positioned.fill(
                          child: ColoredBox(
                            color: widget.tint!.withValues(alpha: 0.75),
                          ),
                        ),
                      if (widget.surfaceColor != null)
                        Positioned.fill(
                          child: ColoredBox(color: widget.surfaceColor!),
                        ),
                      Center(
                        child: Padding(
                          padding: widget.padding,
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

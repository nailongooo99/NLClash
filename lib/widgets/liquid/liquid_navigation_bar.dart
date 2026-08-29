import 'dart:math' as math;

import 'package:fl_clash/widgets/liquid/liquid_drag.dart';
import 'package:fl_clash/widgets/liquid/liquid_glass.dart';
import 'package:fl_clash/widgets/liquid/liquid_highlight.dart';
import 'package:flutter/material.dart';

class LiquidNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;
  final double height;
  final double padding;

  const LiquidNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = 64,
    this.padding = 4,
  }) : assert(destinations.length >= 2);

  @override
  State<LiquidNavigationBar> createState() => _LiquidNavigationBarState();
}

class _LiquidNavigationBarState extends State<LiquidNavigationBar>
    with TickerProviderStateMixin {
  late final LiquidDragController _controller;
  late final LiquidHighlightController _highlight;
  late final AnimationController _panelOffsetController;
  double _barWidth = 0;
  double _lastDragX = 0;

  @override
  void initState() {
    super.initState();
    _controller = LiquidDragController(
      vsync: this,
      initialValue: widget.selectedIndex.toDouble(),
      valueRange: LiquidValueRange(
        0,
        (widget.destinations.length - 1).toDouble(),
      ),
      pressedScale: 78 / 56,
    );
    _highlight = LiquidHighlightController(vsync: this);
    _panelOffsetController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant LiquidNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.animateToValue(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _highlight.dispose();
    _panelOffsetController.dispose();
    super.dispose();
  }

  double get _tabWidth {
    final count = widget.destinations.length;
    if (count == 0) return 0;
    return (_barWidth - widget.padding * 2) / count;
  }

  double get _panelOffset {
    final width = math.max(_barWidth, 1);
    final fraction = (_panelOffsetController.value / width).clamp(-1.0, 1.0);
    return 4 * fraction.sign * Curves.easeOutCubic.transform(fraction.abs());
  }

  void _handleDragStart(DragStartDetails details) {
    _highlight.onDown(details.localPosition);
    _controller.press();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    _lastDragX = details.localPosition.dx;
    _highlight.onMove(Offset(_lastDragX, 0));
    _controller.updateValue(
      (_controller.value + dx / _tabWidth)
          .clamp(0, (widget.destinations.length - 1).toDouble())
          .toDouble(),
    );
    _panelOffsetController.value += dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    _highlight.onUp();
    final index = _controller.value
        .round()
        .clamp(0, widget.destinations.length - 1)
        .toInt();
    _controller.animateToValue(index.toDouble());
    if (index != widget.selectedIndex) {
      widget.onDestinationSelected(index);
    }
    _panelOffsetController.animateTo(
      0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
    );
    _controller.release();
  }

  void _handleDragCancel() {
    _handleDragEnd(DragEndDetails());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF);
    final containerColor = isDark
        ? const Color(0xFF121212).withValues(alpha: 0.4)
        : const Color(0xFFFAFAFA).withValues(alpha: 0.4);
    return LayoutBuilder(
      builder: (context, constraints) {
        _barWidth = constraints.maxWidth;
        final tabWidth = _tabWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([_controller, _highlight]),
          builder: (context, _) {
            final progress = _controller.pressProgress;
            final velocity = _controller.velocity;
            final panelOffset = _panelOffset;
            final pillX = (widget.padding + _controller.value * tabWidth +
                    panelOffset)
                .clamp(-tabWidth * 0.25, _barWidth - tabWidth * 0.75)
                .toDouble();
            final scaleX =
                _controller.scaleX /
                (1 - (velocity * 0.75).clamp(-0.2, 0.2).toDouble());
            final scaleY =
                _controller.scaleY *
                (1 - (velocity * 0.25).clamp(-0.2, 0.2).toDouble());
            final containerScale = 1 + 16 / math.max(_barWidth, 1) * progress;
            final selectedIndex = widget.selectedIndex.clamp(
              0,
              widget.destinations.length - 1,
            );
            final highlightPosition = Offset(
              (_controller.value + 0.5) * tabWidth + panelOffset,
              widget.height / 2,
            );
            return SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.scale(
                      scale: containerScale,
                      child: LiquidGlass(
                        shape: const StadiumBorder(),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        blurSigma: 8,
                        lensHeight: 24,
                        lensAmount: 24,
                        saturation: 1.5,
                        tint: containerColor,
                        tintOpacity: 1,
                        highlight: const LiquidHighlightSpec(alpha: 0.5),
                        enableInnerShadow: false,
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: LiquidHighlightPainter(
                                    progress: progress,
                                    position: highlightPosition,
                                    color: Colors.white,
                                    intensity: 0.15,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < widget.destinations.length;
                                  index++
                                )
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (index != widget.selectedIndex) {
                                          widget.onDestinationSelected(index);
                                        }
                                      },
                                      child: SizedBox(
                                        height:
                                            widget.height - widget.padding * 2,
                                        child: widget.destinations[index],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pillX,
                    top: widget.padding,
                    width: tabWidth,
                    height: widget.height - widget.padding * 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: _handleDragStart,
                      onHorizontalDragUpdate: _handleDragUpdate,
                      onHorizontalDragEnd: _handleDragEnd,
                      onHorizontalDragCancel: _handleDragCancel,
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: LiquidGlass(
                          shape: const StadiumBorder(),
                          borderRadius: BorderRadius.circular(
                            widget.height / 2,
                          ),
                          blurSigma: 8 * (1 - progress),
                          lensHeight: 10 * progress,
                          lensAmount: 14 * progress,
                          chromaticAberration: true,
                          depthEffect: 1,
                          tint: isDark
                              ? const Color(0x1AFFFFFF)
                              : const Color(0x1A000000),
                          tintOpacity: 1 - progress,
                          highlight: LiquidHighlightSpec(
                            alpha: progress,
                          ),
                          enableInnerShadow: progress > 0,
                          innerShadowRadius: 8 * progress,
                          innerShadowIntensity: 0.15 * progress,
                          innerShadowOffset: Offset(0, 8 * progress),
                          shadows: [
                            if (progress > 0)
                              BoxShadow(
                                color: const Color(0x1A000000).withValues(
                                  alpha: progress,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                          ],
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    accent,
                                    BlendMode.srcIn,
                                  ),
                                  child: widget.destinations[selectedIndex],
                                ),
                              ),
                              Positioned.fill(
                                child: ColoredBox(
                                  color: const Color(0x08000000).withValues(
                                    alpha: progress,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

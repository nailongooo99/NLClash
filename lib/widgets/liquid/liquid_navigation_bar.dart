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

  @override
  void initState() {
    super.initState();
    _controller = LiquidDragController(
      vsync: this,
      initialValue: widget.selectedIndex.toDouble(),
      valueRange: LiquidValueRange(0, (widget.destinations.length - 1).toDouble()),
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

  void _handleDragStart(DragStartDetails details) {
    _highlight.onDown(details.localPosition);
    _controller.press();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    _highlight.onMove(details.localPosition);
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
        ? const Color(0xFF121212).withValues(alpha: 0.42)
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
            final pillX =
                (widget.padding + _controller.value * tabWidth + _panelOffsetController.value)
                    .clamp(
                      -tabWidth * 0.25,
                      _barWidth - tabWidth * 0.75,
                    )
                    .toDouble();
            final scaleX =
                _controller.scaleX /
                (1 - (velocity * 0.75).clamp(-0.2, 0.2).toDouble());
            final scaleY =
                _controller.scaleY *
                (1 - (velocity * 0.25).clamp(-0.2, 0.2).toDouble());
            final selectedContent =
                widget.destinations[widget.selectedIndex
                    .clamp(0, widget.destinations.length - 1)
                    .toInt()];
            return SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LiquidGlass(
                      shape: const StadiumBorder(),
                      blurSigma: 8,
                      tint: containerColor,
                      tintOpacity: 1,
                      enableHighlight: false,
                      enableInnerShadow: false,
                      child: Row(
                        children: [
                          for (var index = 0; index < widget.destinations.length; index++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (index != widget.selectedIndex) {
                                    widget.onDestinationSelected(index);
                                  }
                                },
                                child: SizedBox(
                                  height: widget.height - widget.padding * 2,
                                  child: widget.destinations[index],
                                ),
                              ),
                            ),
                        ],
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
                          blurSigma: 8 * (1 - progress),
                          tint: Colors.white,
                          tintOpacity: 0.1,
                          enableHighlight: false,
                          enableInnerShadow: progress > 0,
                          innerShadowRadius: 8 * progress,
                          innerShadowIntensity: 0.1 * progress,
                          lensScale: 1 + progress * 0.06,
                          shadows: [
                            if (progress > 0)
                              const BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                                  child: selectedContent,
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: LiquidHighlightPainter(
                                      progress: progress,
                                      position: _highlight.position,
                                      color: Colors.white,
                                      intensity: 0.1,
                                    ),
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

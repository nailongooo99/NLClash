import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class LiquidValueRange {
  final double start;
  final double end;

  const LiquidValueRange(this.start, this.end);

  double get endInclusive => end;
}

class LiquidSpringSpec {
  final double mass;
  final double stiffness;
  final double damping;

  const LiquidSpringSpec({
    this.mass = 1,
    required this.stiffness,
    required this.damping,
  });

  SpringSimulation simulation(double from, double to) {
    return SpringSimulation(
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping),
      from,
      to,
      0,
    );
  }
}

class LiquidDragController extends ChangeNotifier {
  LiquidDragController({
    required TickerProvider vsync,
    required double initialValue,
    required this.valueRange,
    this.visibilityThreshold = 0.001,
    this.initialScale = 1,
    this.pressedScale = 1.5,
  }) : _value = initialValue.clamp(
         valueRange.start,
         valueRange.endInclusive,
       ).toDouble() {
    _valueController = AnimationController.unbounded(vsync: vsync)
      ..value = _value
      ..addListener(_handleValueTick);
    _velocityController = AnimationController.unbounded(vsync: vsync);
    _pressController = AnimationController.unbounded(vsync: vsync);
    _scaleXController = AnimationController.unbounded(vsync: vsync)
      ..value = initialScale;
    _scaleYController = AnimationController.unbounded(vsync: vsync)
      ..value = initialScale;
    _valueSpring = const LiquidSpringSpec(
      stiffness: 1000,
      damping: 63.245553203367585,
    );
    _pressSpring = const LiquidSpringSpec(
      stiffness: 1000,
      damping: 63.245553203367585,
    );
    _scaleXSpring = const LiquidSpringSpec(
      stiffness: 250,
      damping: 18.973665961010276,
    );
    _scaleYSpring = const LiquidSpringSpec(
      stiffness: 250,
      damping: 22.135943621178654,
    );
    _velocitySpring = const LiquidSpringSpec(
      stiffness: 300,
      damping: 17.320508075688775,
    );
  }

  final LiquidValueRange valueRange;
  final double visibilityThreshold;
  final double initialScale;
  final double pressedScale;

  late final AnimationController _valueController;
  late final AnimationController _velocityController;
  late final AnimationController _pressController;
  late final AnimationController _scaleXController;
  late final AnimationController _scaleYController;
  late final LiquidSpringSpec _valueSpring;
  late final LiquidSpringSpec _pressSpring;
  late final LiquidSpringSpec _scaleXSpring;
  late final LiquidSpringSpec _scaleYSpring;
  late final LiquidSpringSpec _velocitySpring;

  double _value;
  double _lastValueTickTime = 0;
  double _normalizedVelocity = 0;

  double get value => _valueController.value;

  double get targetValue => _valueController.value;

  double get progress {
    final span = valueRange.endInclusive - valueRange.start;
    if (span == 0) return 0;
    return ((_valueController.value - valueRange.start) / span)
        .clamp(0, 1)
        .toDouble();
  }

  double get pressProgress => _pressController.value;

  double get scaleX => _scaleXController.value;

  double get scaleY => _scaleYController.value;

  double get velocity => _normalizedVelocity;

  void press() {
    _run(_pressController, 1, _pressSpring);
    _run(_scaleXController, pressedScale, _scaleXSpring);
    _run(_scaleYController, pressedScale, _scaleYSpring);
  }

  void release() {
    _run(_pressController, 0, _pressSpring);
    _run(_scaleXController, initialScale, _scaleXSpring);
    _run(_scaleYController, initialScale, _scaleYSpring);
  }

  void updateValue(double value) {
    _run(_valueController, value.clamp(
      valueRange.start,
      valueRange.endInclusive,
    ).toDouble(), _valueSpring);
  }

  void animateToValue(double value) {
    press();
    _run(_valueController, value.clamp(
      valueRange.start,
      valueRange.endInclusive,
    ).toDouble(), _valueSpring);
    if (_normalizedVelocity != 0) {
      _run(_velocityController, 0, _velocitySpring);
    }
    release();
  }

  void _handleValueTick() {
    final now = _valueController.lastElapsedDuration?.inMicroseconds.toDouble() ??
        0;
    final dt = (now - _lastValueTickTime) / 1000000;
    _lastValueTickTime = now;
    if (dt <= 0) return;
    final span = valueRange.endInclusive - valueRange.start;
    if (span == 0) return;
    final delta = _valueController.value - _value;
    _value = _valueController.value;
    _normalizedVelocity = delta / dt / span;
    notifyListeners();
  }

  void _run(
    AnimationController controller,
    double target,
    LiquidSpringSpec spec,
  ) {
    controller.animateWith(spec.simulation(controller.value, target));
  }

  @override
  void dispose() {
    _valueController.dispose();
    _velocityController.dispose();
    _pressController.dispose();
    _scaleXController.dispose();
    _scaleYController.dispose();
    super.dispose();
  }
}

class LiquidHighlightController extends ChangeNotifier {
  LiquidHighlightController({required TickerProvider vsync}) {
    _pressController = AnimationController(vsync: vsync, duration: kThemeAnimationDuration);
    _pressController.addListener(() => notifyListeners());
  }

  late final AnimationController _pressController;
  Offset _startPosition = Offset.zero;
  Offset _position = Offset.zero;

  double get pressProgress => _pressController.value;

  Offset get position => _position;

  Offset get offset => _position - _startPosition;

  void onDown(Offset position) {
    _startPosition = position;
    _position = position;
    _pressController.forward();
  }

  void onMove(Offset position) {
    _position = position;
    notifyListeners();
  }

  void onUp() {
    _pressController.reverse();
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }
}

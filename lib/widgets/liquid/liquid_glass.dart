import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_clash/widgets/liquid/liquid_shaders.dart';
import 'package:flutter/material.dart';

enum LiquidHighlightKind { plain, defaultStyle, ambient }

class LiquidHighlightSpec {
  final LiquidHighlightKind kind;
  final double width;
  final double blurRadius;
  final double alpha;
  final Color color;
  final double angle;
  final double falloff;

  const LiquidHighlightSpec({
    this.kind = LiquidHighlightKind.defaultStyle,
    this.width = 0.5,
    this.blurRadius = 0.25,
    this.alpha = 1,
    this.color = const Color(0x80FFFFFF),
    this.angle = 45,
    this.falloff = 1,
  });

  const LiquidHighlightSpec.defaultStyle() : this();

  const LiquidHighlightSpec.ambient({
    this.kind = LiquidHighlightKind.ambient,
    this.width = 0.5,
    this.blurRadius = 0.25,
    this.alpha = 1,
    this.color = const Color(0xFFFFFFFF),
    this.angle = 45,
    this.falloff = 1,
  });
}

List<double> _saturationMatrix(double saturation) {
  const rw = 0.213;
  const gw = 0.715;
  const bw = 0.072;
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

class LiquidGlass extends StatefulWidget {
  final Widget child;
  final ShapeBorder? shape;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color tint;
  final double tintOpacity;
  final double saturation;
  final double lensHeight;
  final double lensAmount;
  final double depthEffect;
  final bool chromaticAberration;
  final LiquidHighlightSpec? highlight;
  final bool enableInnerShadow;
  final double innerShadowRadius;
  final double innerShadowIntensity;
  final Offset innerShadowOffset;
  final List<BoxShadow> shadows;
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
    this.saturation = 1.5,
    this.lensHeight = 0,
    this.lensAmount = 0,
    this.depthEffect = 0,
    this.chromaticAberration = false,
    this.highlight = const LiquidHighlightSpec(),
    this.enableInnerShadow = true,
    this.innerShadowRadius = 5,
    this.innerShadowIntensity = 0.16,
    this.innerShadowOffset = Offset.zero,
    this.shadows = const [],
    this.padding = EdgeInsets.zero,
    this.fit = StackFit.expand,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  bool _shadersReady = LiquidShaders.instance.isReady;

  @override
  void initState() {
    super.initState();
    LiquidShaders.instance.ensureLoaded().then((_) {
      if (mounted && !_shadersReady) {
        setState(() {
          _shadersReady = true;
        });
      }
    });
  }

  ShapeBorder get _shape {
    return widget.shape ??
        RoundedSuperellipseBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        );
  }

  BorderRadius get _borderRadius {
    final shape = widget.shape;
    if (widget.borderRadius != null) {
      return widget.borderRadius!;
    }
    if (shape is RoundedSuperellipseBorder) {
      return shape.borderRadius as BorderRadius;
    }
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius as BorderRadius;
    }
    return BorderRadius.circular(24);
  }

  List<double> _radii(Size size, double dpr) {
    final radius = _borderRadius;
    final maxRadius = size.shortestSide / 2;
    double clamp(double value) => math.min(value * dpr, maxRadius * dpr);
    return [
      clamp(radius.topLeft.x),
      clamp(radius.topRight.x),
      clamp(radius.bottomRight.x),
      clamp(radius.bottomLeft.x),
    ];
  }

  ui.ImageFilter? _buildFilter(Size size, double dpr) {
    final shaderSupported =
        LiquidShaders.instance.supported && widget.lensHeight > 0;
    if (shaderSupported) {
      final shader = LiquidShaders.instance.createRefractionShader();
      final radii = _radii(size, dpr);
      shader.setFloat(0, size.width * dpr);
      shader.setFloat(1, size.height * dpr);
      shader.setFloat(2, 0);
      shader.setFloat(3, 0);
      for (var index = 0; index < 4; index++) {
        shader.setFloat(4 + index, radii[index]);
      }
      shader.setFloat(8, widget.lensHeight * dpr);
      shader.setFloat(9, widget.lensAmount * dpr);
      shader.setFloat(10, widget.depthEffect);
      shader.setFloat(11, widget.chromaticAberration ? 1 : 0);
      return ui.ImageFilter.shader(shader);
    }
    if (widget.blurSigma > 0) {
      return ui.ImageFilter.blur(
        sigmaX: widget.blurSigma,
        sigmaY: widget.blurSigma,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark ? Colors.black : Colors.black54;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: widget.shadows),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
              return widget.child;
            }
            final filter = _buildFilter(size, dpr);
            Widget backdrop = ColoredBox(
              color: widget.tint.withValues(alpha: widget.tintOpacity),
            );
            if (widget.saturation != 1) {
              backdrop = ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _saturationMatrix(widget.saturation),
                ),
                child: backdrop,
              );
            }
            if (filter != null) {
              backdrop = BackdropFilter(filter: filter, child: backdrop);
            }
            return Stack(
              fit: widget.fit,
              children: [
                Positioned.fill(child: backdrop),
                if (widget.highlight != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiquidHighlightPainter(
                        shape: shape,
                        borderRadius: _borderRadius,
                        highlight: widget.highlight!,
                        dpr: dpr,
                      ),
                    ),
                  ),
                if (widget.enableInnerShadow)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiquidInnerShadowPainter(
                        shape: shape,
                        color: shadowColor,
                        radius: widget.innerShadowRadius,
                        intensity: widget.innerShadowIntensity,
                        offset: widget.innerShadowOffset,
                      ),
                    ),
                  ),
                Padding(padding: widget.padding, child: widget.child),
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
  final BorderRadius borderRadius;
  final LiquidHighlightSpec highlight;
  final double dpr;

  const _LiquidHighlightPainter({
    required this.shape,
    required this.borderRadius,
    required this.highlight,
    required this.dpr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    final maxRadius = size.shortestSide / 2;
    double clamp(double value) => math.min(value, maxRadius);
    final radii = [
      clamp(borderRadius.topLeft.x * dpr),
      clamp(borderRadius.topRight.x * dpr),
      clamp(borderRadius.bottomRight.x * dpr),
      clamp(borderRadius.bottomLeft.x * dpr),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          math.min(highlight.width * dpr, maxRadius * dpr).ceil() * 2
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        highlight.blurRadius * dpr,
      )
      ..blendMode = highlight.kind == LiquidHighlightKind.ambient
          ? BlendMode.srcOver
          : BlendMode.plus;
    if (highlight.kind == LiquidHighlightKind.plain ||
        !LiquidShaders.instance.supported) {
      paint.color = highlight.color.withValues(alpha: highlight.alpha);
    } else {
      final shader = LiquidShaders.instance.createHighlightShader();
      shader.setFloat(0, size.width * dpr);
      shader.setFloat(1, size.height * dpr);
      for (var index = 0; index < 4; index++) {
        shader.setFloat(2 + index, radii[index]);
      }
      shader.setFloat(6, 1);
      shader.setFloat(7, 1);
      shader.setFloat(8, 1);
      shader.setFloat(9, 1);
      shader.setFloat(
        10,
        highlight.angle * math.pi / 180,
      );
      shader.setFloat(11, highlight.falloff);
      shader.setFloat(
        12,
        highlight.kind == LiquidHighlightKind.ambient ? 1 : 0,
      );
      shader.setFloat(13, highlight.alpha);
      paint.shader = shader;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidHighlightPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.highlight != highlight ||
        oldDelegate.dpr != dpr;
  }
}

class _LiquidInnerShadowPainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;
  final double radius;
  final double intensity;
  final Offset offset;

  const _LiquidInnerShadowPainter({
    required this.shape,
    required this.color,
    required this.radius,
    required this.intensity,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(offset.dx, offset.dy);
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
        oldDelegate.intensity != intensity ||
        oldDelegate.offset != offset;
  }
}

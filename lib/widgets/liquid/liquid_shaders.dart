import 'dart:ui' show FragmentProgram, FragmentShader, ImageFilter;

class LiquidShaders {
  LiquidShaders._();

  static final LiquidShaders instance = LiquidShaders._();

  FragmentProgram? _refraction;
  FragmentProgram? _highlight;
  Future<void>? _loading;
  bool _failed = false;

  bool get isReady => _refraction != null && _highlight != null && !_failed;

  bool get supported {
    return ImageFilter.isShaderFilterSupported && isReady;
  }

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        FragmentProgram.fromAsset('assets/shaders/refraction_dispersion.frag'),
        FragmentProgram.fromAsset('assets/shaders/highlight.frag'),
      ]);
      _refraction = results[0];
      _highlight = results[1];
    } catch (_) {
      _failed = true;
    }
  }

  FragmentShader createRefractionShader() {
    return _refraction!.fragmentShader();
  }

  FragmentShader createHighlightShader() {
    return _highlight!.fragmentShader();
  }
}

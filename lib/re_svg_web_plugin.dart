import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin registrar for `re_svg_new`.
///
/// Rendering on web is handled entirely in Dart through conditional imports
/// (see `resvg_web.dart`), so there is nothing to register here. This class
/// only exists so the Flutter tooling recognises web as a supported platform
/// and does not emit a "plugin does not support web" warning.
class ReSvgWeb {
  static void registerWith(Registrar registrar) {
    // No-op: the public API is provided via conditional imports.
  }
}

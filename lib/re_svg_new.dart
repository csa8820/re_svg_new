import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'resvg_ffi.dart' if (dart.library.js_interop) 'resvg_web.dart';

class SvgView extends StatefulWidget {
  final String data;
  final bool intrinsic;

  /// Optional custom fonts to register before parsing. Required when the
  /// SVG contains `<text>` referencing a font that is not installed on
  /// the host OS.
  final ResvgFonts fonts;

  const SvgView({
    super.key,
    required this.data,
    this.intrinsic = false,
    this.fonts = ResvgFonts.systemOnly,
  });
  @override
  State<SvgView> createState() => _SvgViewState();
}

class _SvgViewState extends State<SvgView> {
  late Future<ReSvg> _reSvg;

  @override
  void initState() {
    super.initState();
    _reSvg = ReSvg.spawn(widget.data, fonts: widget.fonts);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data != oldWidget.data || widget.fonts != oldWidget.fonts) {
      _clean();
      _reSvg = ReSvg.spawn(widget.data, fonts: widget.fonts);
    }
  }

  @override
  void dispose() {
    _clean();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      return FutureBuilder(
          future: _getImage(constraints, devicePixelRatio),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return RawImage(
                image: snapshot.data,
                scale: devicePixelRatio,
              );
            } else {
              return const CircularProgressIndicator();
            }
          });
    });
  }

  Future<ui.Image?> _getImage(
      BoxConstraints constraints, double devicePixelRatio) async {
    final reSvg = await _reSvg;
    final size = await reSvg.getSize();
    if (size == null) {
      return null;
    } else {
      final (width, height) =
          _getPhysicalSize(size, constraints, devicePixelRatio);
      final image = await reSvg.render(width, height);
      return image;
    }
  }

  void _clean() {
    _reSvg.then((reSvg) => reSvg.close());
  }

  (int, int) _getPhysicalSize(
      Size size, BoxConstraints constraints, double devicePixelRatio) {
    final ratio = size.width / size.height;
    double logicalWidth, logicalHeight;

    if (constraints.maxWidth == double.infinity) {
      if (constraints.maxHeight == double.infinity) {
        logicalWidth = size.width;
        logicalHeight = size.height;
      } else {
        if (widget.intrinsic) {
          if (size.height > constraints.maxHeight) {
            logicalHeight = constraints.maxHeight;
            logicalWidth = logicalHeight * ratio;
          } else {
            logicalHeight = size.height;
            logicalWidth = size.width;
          }
        } else {
          logicalHeight = constraints.maxHeight;
          logicalWidth = logicalHeight * ratio;
        }
      }
    } else if (constraints.maxHeight == double.infinity) {
      if (widget.intrinsic) {
        if (size.width > constraints.maxWidth) {
          logicalWidth = constraints.maxWidth;
          logicalHeight = logicalWidth / ratio;
        } else {
          logicalWidth = size.width;
          logicalHeight = size.height;
        }
      } else {
        logicalWidth = constraints.maxWidth;
        logicalHeight = logicalWidth / ratio;
      }
    } else {
      final boxRatio = constraints.maxWidth / constraints.maxHeight;
      if (ratio > boxRatio) {
        if (widget.intrinsic) {
          if (size.width > constraints.maxWidth) {
            logicalWidth = constraints.maxWidth;
            logicalHeight = logicalWidth / ratio;
          } else {
            logicalWidth = size.width;
            logicalHeight = size.height;
          }
        } else {
          logicalWidth = constraints.maxWidth;
          logicalHeight = logicalWidth / ratio;
        }
      } else {
        if (widget.intrinsic) {
          if (size.height > constraints.maxHeight) {
            logicalHeight = constraints.maxHeight;
            logicalWidth = logicalHeight * ratio;
          } else {
            logicalHeight = size.height;
            logicalWidth = size.width;
          }
        } else {
          logicalHeight = constraints.maxHeight;
          logicalWidth = logicalHeight * ratio;
        }
      }
    }

    final physicalWidth = logicalWidth * devicePixelRatio;
    final physicalHeight = logicalHeight * devicePixelRatio;
    return (physicalWidth.round(), physicalHeight.round());
  }
}

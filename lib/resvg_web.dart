import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:web/web.dart' as web;

/// Web counterpart of the native [ResvgFonts]. Kept API-compatible so the
/// rest of the package compiles unchanged under conditional imports.
///
/// On web we delegate rendering to the browser, which uses the system /
/// document fonts. Custom font blobs and the system-font toggle are accepted
/// for source compatibility but have no effect here.
class ResvgFonts {
  /// Raw font data blobs (ignored on web).
  final List<Uint8List> data;

  /// Optional default sans-serif family (ignored on web).
  final String? defaultFamily;

  /// Whether to load OS fonts (ignored on web).
  final bool loadSystemFonts;

  const ResvgFonts({
    this.data = const [],
    this.defaultFamily,
    this.loadSystemFonts = true,
  });

  static const ResvgFonts systemOnly = ResvgFonts();
}

/// Web implementation of [ReSvg]. Renders the SVG through the browser by
/// loading it into an `<img>` element and rasterising onto a `<canvas>`.
///
/// The public surface mirrors the native FFI implementation so [SvgView]
/// works without changes.
class ReSvg {
  final String _data;
  web.HTMLImageElement? _img;
  Size? _size;
  bool _closed = false;
  late final Future<void> _ready;

  ReSvg._(this._data) {
    _ready = _load();
  }

  static Future<ReSvg> spawn(
    String data, {
    ResvgFonts fonts = ResvgFonts.systemOnly,
  }) async {
    return ReSvg._(data);
  }

  Future<void> _load() async {
    final url =
        'data:image/svg+xml;base64,${base64Encode(utf8.encode(_data))}';
    final img = web.HTMLImageElement();
    final completer = Completer<void>();
    final loadHandler = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    final errorHandler = (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load SVG'));
      }
    }.toJS;
    img.addEventListener('load', loadHandler);
    img.addEventListener('error', errorHandler);
    img.src = url;

    try {
      await completer.future;
    } catch (_) {
      _size = null;
      return;
    }

    _img = img;

    double w = img.naturalWidth.toDouble();
    double h = img.naturalHeight.toDouble();
    if (w <= 0 || h <= 0) {
      final parsed = _parseSvgSize(_data);
      if (parsed != null) {
        w = parsed.width;
        h = parsed.height;
      }
    }
    _size = (w > 0 && h > 0) ? Size(w, h) : null;
  }

  Future<Size?> getSize() async {
    if (_closed) return null;
    await _ready;
    return _size;
  }

  Future<ui.Image?> render(int width, int height) async {
    if (_closed || width <= 0 || height <= 0) return null;
    await _ready;
    final img = _img;
    if (img == null) return null;

    final canvas = (web.document.createElement('canvas') as web.HTMLCanvasElement)
      ..width = width
      ..height = height;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0, width.toDouble(), height.toDouble());

    final imageData = ctx.getImageData(0, 0, width, height);
    final clamped = imageData.data.toDart;
    final pixels = Uint8List.view(clamped.buffer);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  void close() {
    _closed = true;
    _img = null;
  }
}

/// Best-effort parse of the SVG intrinsic size from `width`/`height` or the
/// `viewBox` attribute, used only when the browser reports a zero natural
/// size (SVGs without explicit dimensions).
Size? _parseSvgSize(String svg) {
  final widthMatch =
      RegExp(r'''\bwidth\s*=\s*["']([\d.]+)''').firstMatch(svg);
  final heightMatch =
      RegExp(r'''\bheight\s*=\s*["']([\d.]+)''').firstMatch(svg);
  if (widthMatch != null && heightMatch != null) {
    final w = double.tryParse(widthMatch.group(1)!);
    final h = double.tryParse(heightMatch.group(1)!);
    if (w != null && h != null && w > 0 && h > 0) return Size(w, h);
  }

  final viewBox =
      RegExp(r'''\bviewBox\s*=\s*["']([^"']+)["']''').firstMatch(svg);
  if (viewBox != null) {
    final parts = viewBox
        .group(1)!
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (parts.length == 4 && parts[2] != null && parts[3] != null) {
      final w = parts[2]!;
      final h = parts[3]!;
      if (w > 0 && h > 0) return Size(w, h);
    }
  }
  return null;
}

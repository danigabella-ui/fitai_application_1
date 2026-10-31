import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Nagyon halvány, szemcsés "filmes" textúra a háttérre.
/// A zajmintát egyszer generálja le, utána ismétlődő mintaként rajzolja.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({super.key, this.opacity = 0.09});

  final double opacity;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> {
  static Future<ui.Image>? _noise;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _noise ??= _createNoise();
    _noise!.then((image) {
      if (mounted) setState(() => _image = image);
    });
  }

  static Future<ui.Image> _createNoise() {
    const size = 128;
    final random = math.Random(7);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final value = random.nextBool() ? 255 : 0;
      pixels[i * 4] = value;
      pixels[i * 4 + 1] = value;
      pixels[i * 4 + 2] = value;
      pixels[i * 4 + 3] = random.nextInt(256);
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GrainPainter(image, widget.opacity),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.image, this.opacity);

  final ui.Image image;
  final double opacity;

  /// Fél méretre kicsinyítve, hogy a szemcsék finomak legyenek.
  static final Float64List _matrix = Float64List.fromList(const [
    0.5, 0, 0, 0, //
    0, 0.5, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.ImageShader(
        image,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        _matrix,
      )
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.opacity != opacity;
}

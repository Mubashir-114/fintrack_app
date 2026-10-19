import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// A square crop with focal-position and zoom controls, before any upload.
class AvatarEditor extends StatefulWidget {
  const AvatarEditor({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  img.Image? _image;
  Uint8List? _preview;
  double _x = .5, _y = .5, _zoom = 1;
  @override
  void initState() {
    super.initState();
    try {
      final decoded = img.decodeImage(widget.bytes);
      if (decoded != null) _image = img.bakeOrientation(decoded);
      _render();
    } catch (_) {
      /* Invalid images show the recovery text. */
    }
  }

  void _render() {
    final source = _image;
    if (source == null) return;
    final side = (math.min(source.width, source.height) / _zoom).round();
    final crop = img.copyCrop(
      source,
      x: ((source.width - side) * _x).round(),
      y: ((source.height - side) * _y).round(),
      width: side,
      height: side,
    );
    _preview = Uint8List.fromList(
      img.encodeJpg(img.copyResize(crop, width: 384, height: 384), quality: 80),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crop profile photo')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_preview == null)
            const Text('This image cannot be read. Choose another photo.')
          else ...[
            Center(
              child: ClipOval(
                child: Image.memory(
                  _preview!,
                  width: 224,
                  height: 224,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Zoom'),
            Slider(
              value: _zoom,
              min: 1,
              max: 3,
              onChanged: (v) => setState(() {
                _zoom = v;
                _render();
              }),
            ),
            const Text('Horizontal position'),
            Slider(
              value: _x,
              onChanged: (v) => setState(() {
                _x = v;
                _render();
              }),
            ),
            const Text('Vertical position'),
            Slider(
              value: _y,
              onChanged: (v) => setState(() {
                _y = v;
                _render();
              }),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _preview),
              child: const Text('Use photo'),
            ),
          ],
        ],
      ),
    ),
  );
}

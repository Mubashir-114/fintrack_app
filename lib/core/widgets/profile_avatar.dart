import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.bytes,
    this.size = 64,
  });
  final String name;
  final Uint8List? bytes;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? 'U' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * .36,
        ),
      ),
    );
    return Semantics(
      label: 'Profile photo',
      image: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .12),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: bytes == null
            ? fallback
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, error, stack) => fallback,
              ),
      ),
    );
  }
}

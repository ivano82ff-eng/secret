import 'package:flutter/material.dart';

import '../theme.dart';

/// Soft abstract wash behind a thread. Bubbles stay on top of it.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, this.locked = false});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = SecretPalette.of(context);
    return ClipRect(
      child: CustomPaint(
        key: Key(locked ? 'lock-wallpaper' : 'thread-wallpaper'),
        painter: locked
            ? _LockWallpaperPainter(palette)
            : _WallpaperPainter(palette),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter(this.palette);

  final SecretPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.wallpaperBase);
    final night = palette.night;
    _blob(
      canvas,
      size,
      const Offset(0.12, 0.18),
      0.42,
      palette.blobA,
      night ? 0.42 : 0.55,
    );
    _blob(
      canvas,
      size,
      const Offset(0.86, 0.72),
      0.5,
      palette.blobB,
      night ? 0.38 : 0.4,
    );
    _blob(
      canvas,
      size,
      const Offset(0.48, 0.92),
      0.36,
      palette.blobC,
      night ? 0.22 : 0.32,
    );
    _blob(
      canvas,
      size,
      const Offset(0.7, 0.16),
      0.22,
      palette.blobA,
      night ? 0.2 : 0.28,
    );
    _blob(
      canvas,
      size,
      const Offset(0.28, 0.55),
      0.16,
      palette.blobB,
      night ? 0.18 : 0.22,
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.04
      ..color = palette.blobB.withValues(alpha: night ? 0.16 : 0.18);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.78),
        radius: size.shortestSide * 0.28,
      ),
      0.4,
      1.6,
      false,
      arc,
    );
    canvas.restore();
  }

  void _blob(
    Canvas canvas,
    Size size,
    Offset anchor,
    double radiusFactor,
    Color color,
    double alpha,
  ) {
    canvas.drawCircle(
      Offset(size.width * anchor.dx, size.height * anchor.dy),
      size.shortestSide * radiusFactor,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter oldDelegate) {
    return oldDelegate.palette.night != palette.night;
  }
}

/// Two or three translucent chat bubbles. Replaces the old lock tile.
class _LockWallpaperPainter extends CustomPainter {
  _LockWallpaperPainter(this.palette);

  final SecretPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.wallpaperBase);
    final night = palette.night;
    _bubble(
      canvas,
      size,
      const Offset(0.28, 0.30),
      0.72,
      0.30,
      palette.blobA,
      night ? 0.38 : 0.30,
      outgoing: true,
    );
    _bubble(
      canvas,
      size,
      const Offset(0.74, 0.58),
      0.46,
      0.20,
      palette.blobB,
      night ? 0.32 : 0.24,
      outgoing: false,
    );
    _bubble(
      canvas,
      size,
      const Offset(0.36, 0.82),
      0.28,
      0.13,
      palette.blobC,
      night ? 0.28 : 0.22,
      outgoing: true,
    );
    canvas.restore();
  }

  void _bubble(
    Canvas canvas,
    Size size,
    Offset anchor,
    double widthFactor,
    double heightFactor,
    Color color,
    double alpha, {
    required bool outgoing,
  }) {
    final shortest = size.shortestSide;
    final width = shortest * widthFactor;
    final height = shortest * heightFactor;
    final rect = Rect.fromCenter(
      center: Offset(size.width * anchor.dx, size.height * anchor.dy),
      width: width,
      height: height,
    );
    final round = Radius.circular(height * 0.42);
    final tail = Radius.circular(height * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: round,
        topRight: round,
        bottomLeft: outgoing ? round : tail,
        bottomRight: outgoing ? tail : round,
      ),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _LockWallpaperPainter oldDelegate) {
    return oldDelegate.palette.night != palette.night;
  }
}

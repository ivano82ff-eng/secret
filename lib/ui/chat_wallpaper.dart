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

class _LockWallpaperPainter extends CustomPainter {
  _LockWallpaperPainter(this.palette);

  final SecretPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final base = palette.night
        ? const Color(0xFF1A2433)
        : const Color(0xFFD7DEE8);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final ink = palette.night
        ? const Color(0xFFE4D2B0).withValues(alpha: 0.38)
        : const Color(0xFF3D4E63).withValues(alpha: 0.32);
    const step = 84.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        _drawLock(canvas, Offset(x, y), 22, ink);
      }
    }
    canvas.restore();
  }

  void _drawLock(Canvas canvas, Offset center, double extent, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = extent * 0.08
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, extent * 0.16),
          width: extent * 0.7,
          height: extent * 0.52,
        ),
        Radius.circular(extent * 0.08),
      ),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(0, -extent * 0.02),
        width: extent * 0.4,
        height: extent * 0.42,
      ),
      3.15,
      3.15,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LockWallpaperPainter oldDelegate) {
    return oldDelegate.palette.night != palette.night;
  }
}

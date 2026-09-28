import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Geometric pattern behind a thread, in the blue-gray palette.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, this.locked = false});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = SecretPalette.of(context);
    return ClipRect(
      child: CustomPaint(
        key: Key(locked ? 'lock-wallpaper' : 'thread-wallpaper'),
        painter: _PatternPainter(palette, locked: locked),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Two locks and a key, drawn inside the composer of an encrypted chat.
class LockFieldMark extends StatelessWidget {
  const LockFieldMark({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SecretPalette.of(context);
    return CustomPaint(
      key: const Key('lock-field-mark'),
      size: const Size(84, 32),
      painter: _LockFieldPainter(
        ink: palette.lockedInk,
        hole: palette.lockedField,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.palette, {required this.locked});

  final SecretPalette palette;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final base = locked ? palette.lockedWallpaper : palette.wallpaperBase;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final night = palette.night;
    final line = (night ? const Color(0xFFD7E8F6) : const Color(0xFF2F6FA8))
        .withValues(
          alpha: locked ? (night ? 0.62 : 0.5) : (night ? 0.4 : 0.34),
        );
    final soft = (night ? const Color(0xFF6AA6D4) : const Color(0xFF7AA6C9))
        .withValues(alpha: locked ? 0.28 : 0.18);
    _orb(
      canvas,
      Offset(size.width * 0.08, size.height * 0.12),
      size.shortestSide * 0.42,
      soft,
    );
    _orb(
      canvas,
      Offset(size.width * 0.92, size.height * 0.78),
      size.shortestSide * 0.5,
      soft,
    );
    const step = 156.0;
    final stroke = locked ? 1.7 : 1.45;
    final rows = (size.height / step).ceil() + 1;
    final cols = (size.width / step).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      final shift = row.isOdd ? step * 0.48 : 0.0;
      for (var col = 0; col < cols; col++) {
        final center = Offset(col * step + shift - 20, row * step + 18);
        switch ((row * 3 + col) % 7) {
          case 0:
            _triangle(canvas, center, 28, -0.4, line, stroke);
          case 1:
            _diamond(canvas, center, 34, line, stroke);
          case 2:
            _hatch(canvas, center, line, stroke);
          case 3:
            _ring(canvas, center, 11, line, stroke);
          case 4:
            _ray(canvas, center, line, stroke);
          case 5:
            _spiral(canvas, center, 26, line, stroke);
          default:
            _cube(canvas, center, line, stroke);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.palette.night != palette.night ||
        oldDelegate.locked != locked;
  }
}

void _orb(Canvas canvas, Offset center, double radius, Color color) {
  canvas.drawCircle(center, radius, Paint()..color = color);
}

void _triangle(
  Canvas canvas,
  Offset center,
  double side,
  double rotation,
  Color color,
  double stroke,
) {
  final path = Path();
  for (var i = 0; i < 3; i++) {
    final angle = rotation + (i * 2 * math.pi / 3) - math.pi / 2;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * side;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );
}

void _diamond(
  Canvas canvas,
  Offset center,
  double extent,
  Color color,
  double stroke,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(0.36);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: extent, height: extent),
      const Radius.circular(3),
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color,
  );
  canvas.restore();
}

void _hatch(Canvas canvas, Offset center, Color color, double stroke) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round
    ..color = color;
  for (var i = 0; i < 5; i++) {
    final y = center.dy + (i - 2) * 6;
    canvas.drawLine(
      Offset(center.dx - 16, y),
      Offset(center.dx + 16, y),
      paint,
    );
  }
}

void _ring(
  Canvas canvas,
  Offset center,
  double radius,
  Color color,
  double stroke,
) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color,
  );
}

void _ray(Canvas canvas, Offset center, Color color, double stroke) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke + 0.6
    ..strokeCap = StrokeCap.round
    ..color = color;
  canvas.drawLine(
    center + const Offset(-34, 22),
    center + const Offset(34, -22),
    paint,
  );
}

void _spiral(
  Canvas canvas,
  Offset center,
  double maxRadius,
  Color color,
  double stroke,
) {
  final path = Path();
  const turns = 2.2;
  const steps = 48;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final angle = t * turns * 2 * math.pi;
    final radius = maxRadius * (0.12 + 0.88 * t);
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color,
  );
}

void _cube(Canvas canvas, Offset center, Color color, double stroke) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeJoin = StrokeJoin.round
    ..color = color;
  const front = [
    Offset(-14, -6),
    Offset(8, -6),
    Offset(8, 16),
    Offset(-14, 16),
  ];
  const back = [Offset(-4, -16), Offset(18, -16), Offset(18, 6), Offset(-4, 6)];
  Path box(List<Offset> corners) {
    final path = Path()
      ..moveTo(center.dx + corners[0].dx, center.dy + corners[0].dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(center.dx + corner.dx, center.dy + corner.dy);
    }
    return path..close();
  }

  canvas.drawPath(box(front), paint);
  canvas.drawPath(box(back), paint);
  for (var i = 0; i < 4; i++) {
    canvas.drawLine(center + front[i], center + back[i], paint);
  }
}

class _LockFieldPainter extends CustomPainter {
  _LockFieldPainter({required this.ink, required this.hole});

  final Color ink;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 84, size.height / 32);
    _lockGlyph(canvas, const Offset(15, 18), 20, -0.22, ink, hole);
    _lockGlyph(canvas, const Offset(40, 17.5), 26, 0.12, ink, hole);
    _keyGlyph(canvas, const Offset(66, 16.5), 28, 0.42, ink, hole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LockFieldPainter oldDelegate) {
    return oldDelegate.ink != ink || oldDelegate.hole != hole;
  }
}

void _lockGlyph(
  Canvas canvas,
  Offset center,
  double extent,
  double rotation,
  Color ink,
  Color hole,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  final bodyTop = -extent * 0.02;
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(-extent * 0.36, bodyTop, extent * 0.72, extent * 0.48),
    Radius.circular(extent * 0.12),
  );
  canvas.drawRRect(body, Paint()..color = ink);
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(0, bodyTop),
      width: extent * 0.4,
      height: extent * 0.4,
    ),
    math.pi,
    -math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = extent * 0.1
      ..strokeCap = StrokeCap.round
      ..color = ink,
  );
  final cut = Paint()..color = hole;
  canvas.drawCircle(Offset(0, bodyTop + extent * 0.2), extent * 0.07, cut);
  final slot = Path()
    ..moveTo(-extent * 0.04, bodyTop + extent * 0.24)
    ..lineTo(extent * 0.04, bodyTop + extent * 0.24)
    ..lineTo(0, bodyTop + extent * 0.4)
    ..close();
  canvas.drawPath(slot, cut);
  canvas.restore();
}

void _keyGlyph(
  Canvas canvas,
  Offset center,
  double extent,
  double rotation,
  Color ink,
  Color hole,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = extent * 0.075
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = ink;
  canvas.drawCircle(Offset(-extent * 0.18, 0), extent * 0.2, stroke);
  canvas.drawCircle(
    Offset(-extent * 0.18, 0),
    extent * 0.08,
    Paint()..color = hole,
  );
  canvas.drawLine(Offset(0, 0), Offset(extent * 0.42, 0), stroke);
  canvas.drawLine(
    Offset(extent * 0.24, 0),
    Offset(extent * 0.24, extent * 0.14),
    stroke,
  );
  canvas.drawLine(
    Offset(extent * 0.36, 0),
    Offset(extent * 0.36, extent * 0.1),
    stroke,
  );
  canvas.restore();
}

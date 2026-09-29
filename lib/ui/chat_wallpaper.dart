import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

/// Thread background. Facets by default; geometry and drops are choices.
/// Extra encryption replaces the choice with soap bubbles.
class ChatWallpaper extends ConsumerWidget {
  const ChatWallpaper({super.key, this.locked = false});

  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(wallpaperProvider);
    final painter = locked
        ? const _BubblesPainter()
        : switch (style) {
            ThreadWallpaper.facets => const _FacetsPainter(),
            ThreadWallpaper.geometry => const _GeometryPainter(),
            ThreadWallpaper.drops => const _DropsPainter(),
          };
    return KeyedSubtree(
      key: Key(locked ? 'lock-style' : 'wallpaper-${style.name}'),
      child: ClipRect(
        child: CustomPaint(
          key: Key(locked ? 'lock-wallpaper' : 'thread-wallpaper'),
          painter: painter,
          child: const SizedBox.expand(),
        ),
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

class _FacetsPainter extends CustomPainter {
  const _FacetsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1E2126),
    );
    const step = 46.0;
    Offset point(int x, int y) {
      final jx = (_hash(x, y) % 19 - 9) * 1.3;
      final jy = (_hash(y + 4, x) % 19 - 9) * 1.3;
      return Offset(x * step + jx, y * step + jy);
    }

    final cols = (size.width / step).ceil() + 2;
    final rows = (size.height / step).ceil() + 2;
    for (var y = -1; y < rows; y++) {
      for (var x = -1; x < cols; x++) {
        final a = point(x, y);
        final b = point(x + 1, y);
        final c = point(x, y + 1);
        final d = point(x + 1, y + 1);
        _facet(canvas, a, b, d, _facetShade(x, y));
        _facet(canvas, a, d, c, _facetShade(x + 7, y + 3));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FacetsPainter oldDelegate) => false;
}

class _GeometryPainter extends CustomPainter {
  const _GeometryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF140B22),
    );
    _orb(
      canvas,
      Offset(size.width * 0.18, size.height * 0.14),
      size.shortestSide * 0.4,
      const Color(0xFFE445B0).withValues(alpha: 0.55),
    );
    _orb(
      canvas,
      Offset(size.width * 0.88, size.height * 0.8),
      size.shortestSide * 0.46,
      const Color(0xFF7A4DFF).withValues(alpha: 0.42),
    );
    const pink = Color(0xFFFF4FA3);
    const violet = Color(0xFFC9A6FF);
    const step = 150.0;
    final rows = (size.height / step).ceil() + 1;
    final cols = (size.width / step).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      final shift = row.isOdd ? step * 0.46 : 0.0;
      for (var col = 0; col < cols; col++) {
        final center = Offset(col * step + shift - 16, row * step + 20);
        final color = (row + col).isEven ? pink : violet;
        switch ((row * 3 + col) % 7) {
          case 0:
            _triangle(canvas, center, 26, -0.5, color, 1.6);
          case 1:
            _diamond(canvas, center, 36, color, 1.7);
          case 2:
            _hatch(canvas, center, color, 1.4);
          case 3:
            _ring(canvas, center, 10, color, 1.5);
          case 4:
            _ray(canvas, center, color, 1.6);
          case 5:
            _spiral(canvas, center, 24, color, 1.4);
          default:
            _cube(canvas, center, color, 1.3);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter oldDelegate) => false;
}

class _DropsPainter extends CustomPainter {
  const _DropsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EAEE), Color(0xFF8E949C)],
        ).createShader(rect),
    );
    final count = (size.width * size.height / 3200).clamp(36, 140).round();
    for (var i = 0; i < count; i++) {
      final x = (_hash(i, 11) % 10000) / 10000 * size.width;
      final y = (_hash(i, 29) % 10000) / 10000 * size.height;
      final big = _hash(i, 5) % 9 == 0;
      final radius = big ? 12.0 + (_hash(i, 7) % 20) : 1.6 + (_hash(i, 7) % 7);
      _drop(canvas, Offset(x, y), radius);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DropsPainter oldDelegate) => false;
}

class _BubblesPainter extends CustomPainter {
  const _BubblesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF07080C),
    );
    const count = 42;
    for (var i = 0; i < count; i++) {
      final x = (_hash(i, 3) % 10000) / 10000 * size.width;
      final y = (_hash(i, 8) % 10000) / 10000 * size.height;
      final radius = i < 7
          ? 26.0 + (_hash(i, 13) % 48)
          : 3.0 + (_hash(i, 13) % 14);
      _soapBubble(canvas, Offset(x, y), radius);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => false;
}

int _hash(int x, int y) {
  var n = (x + 19) * 374761393 + (y + 41) * 668265263;
  n = (n ^ (n >> 13)) * 1274126177;
  return n & 0x7fffffff;
}

Color _facetShade(int x, int y) {
  final n = _hash(x, y) % 100;
  if (n > 93) return const Color(0xFFD7DBE2);
  if (n > 80) return const Color(0xFF8E949E);
  if (n > 58) return const Color(0xFF4C525C);
  if (n > 32) return const Color(0xFF343840);
  return const Color(0xFF22262C);
}

void _facet(Canvas canvas, Offset a, Offset b, Offset c, Color color) {
  final path = Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _drop(Canvas canvas, Offset center, double radius) {
  canvas.drawCircle(
    center,
    radius,
    Paint()..color = Colors.white.withValues(alpha: 0.28),
  );
  canvas.drawCircle(
    center + Offset(radius * 0.06, radius * 0.16),
    radius * 0.9,
    Paint()..color = const Color(0xFF4E555E).withValues(alpha: 0.16),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.09).clamp(0.5, 1.5)
      ..color = Colors.white.withValues(alpha: 0.72),
  );
  canvas.drawCircle(
    center + Offset(-radius * 0.28, -radius * 0.3),
    radius * 0.2,
    Paint()..color = Colors.white.withValues(alpha: 0.9),
  );
}

void _soapBubble(Canvas canvas, Offset center, double radius) {
  canvas.drawCircle(
    center,
    radius,
    Paint()..color = const Color(0xFFB388FF).withValues(alpha: 0.08),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.045).clamp(1.1, 2.8)
      ..color = Colors.white.withValues(alpha: 0.82),
  );
  canvas.drawCircle(
    center,
    radius * 0.9,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.03).clamp(0.7, 1.8)
      ..color = const Color(0xFF9B6DFF).withValues(alpha: 0.5),
  );
  canvas.drawArc(
    Rect.fromCircle(
      center: center + Offset(-radius * 0.04, -radius * 0.06),
      radius: radius * 0.7,
    ),
    math.pi * 1.15,
    math.pi * 0.5,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (radius * 0.055).clamp(1, 2.6)
      ..color = Colors.white.withValues(alpha: 0.92),
  );
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

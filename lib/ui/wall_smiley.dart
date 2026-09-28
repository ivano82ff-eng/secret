import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original animated face that knocks its head on a brick wall.
///
/// Drawn in Flutter. Not ICQ artwork.
class WallSmiley extends StatefulWidget {
  const WallSmiley({super.key, this.size = 72});

  final double size;

  @override
  State<WallSmiley> createState() => _WallSmileyState();
}

class _WallSmileyState extends State<WallSmiley>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.82,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(painter: _WallSmileyPainter(_controller.value));
        },
      ),
    );
  }
}

class _WallSmileyPainter extends CustomPainter {
  _WallSmileyPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final wallLeft = size.width * 0.68;
    _bricks(canvas, size, wallLeft);

    final approach = Curves.easeIn.transform((t / 0.55).clamp(0, 1));
    final squash = t >= 0.55 && t < 0.72;
    final recoil = t >= 0.72
        ? Curves.easeOut.transform(((t - 0.72) / 0.28).clamp(0, 1))
        : 0.0;
    final travel = squash ? 1.0 : (t < 0.55 ? approach : 1 - recoil);
    final faceRadius = size.height * 0.34;
    final restX = faceRadius + 2;
    final hitX = wallLeft - faceRadius * 0.72;
    final cx = restX + (hitX - restX) * travel;
    final cy = size.height * 0.52;
    final scaleX = squash ? 0.72 : 1.0;
    final scaleY = squash ? 1.18 : 1.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scaleX, scaleY);
    final face = Paint()..color = const Color(0xFFF6C445);
    canvas.drawCircle(Offset.zero, faceRadius, face);
    canvas.drawCircle(
      Offset.zero,
      faceRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFC89616),
    );
    final ink = Paint()..color = const Color(0xFF2A241C);
    if (squash) {
      _dizzy(canvas, faceRadius, ink);
    } else {
      canvas.drawCircle(
        Offset(-faceRadius * 0.32, -faceRadius * 0.12),
        2.2,
        ink,
      );
      canvas.drawCircle(
        Offset(faceRadius * 0.32, -faceRadius * 0.12),
        2.2,
        ink,
      );
      final smile = Path()
        ..moveTo(-faceRadius * 0.34, faceRadius * 0.22)
        ..quadraticBezierTo(
          0,
          faceRadius * 0.55,
          faceRadius * 0.34,
          faceRadius * 0.22,
        );
      canvas.drawPath(
        smile,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2A241C),
      );
    }
    canvas.restore();
  }

  void _bricks(Canvas canvas, Size size, double left) {
    const brick = Color(0xFFB55245);
    const mortar = Color(0xFFE7D3C4);
    final paint = Paint()..color = brick;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, size.width - left, size.height),
      Paint()..color = mortar,
    );
    const rows = 5;
    final rowH = size.height / rows;
    for (var row = 0; row < rows; row++) {
      final offset = row.isOdd ? 8.0 : 0.0;
      var x = left - offset;
      while (x < size.width) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 1, row * rowH + 1, 16, rowH - 2),
            const Radius.circular(1),
          ),
          paint,
        );
        x += 18;
      }
    }
  }

  void _dizzy(Canvas canvas, double radius, Paint ink) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = ink.color;
    for (final dx in [-0.28, 0.28]) {
      final center = Offset(radius * dx, -radius * 0.08);
      canvas.drawLine(
        center + const Offset(-3, -3),
        center + const Offset(3, 3),
        stroke,
      );
      canvas.drawLine(
        center + const Offset(-3, 3),
        center + const Offset(3, -3),
        stroke,
      );
    }
    final mouth = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(0, radius * 0.28),
          radius: radius * 0.16,
        ),
        math.pi,
        math.pi,
      );
    canvas.drawPath(mouth, stroke);
  }

  @override
  bool shouldRepaint(covariant _WallSmileyPainter oldDelegate) =>
      oldDelegate.t != t;
}

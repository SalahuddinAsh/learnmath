import 'dart:math';

import 'package:flutter/material.dart';

/// Analog clock showing h:m — a port of clockSVG() in app.js (drawn on a
/// 200×200 grid and scaled). [night] gives the dark face used for 12:00 and
/// later on the 24-hour clock.
class ClockFace extends StatelessWidget {
  final int h;
  final int m;
  final bool night;
  final double size;
  const ClockFace({
    super.key,
    required this.h,
    required this.m,
    this.night = false,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ClockPainter(h, m, night)),
  );
}

class _ClockPainter extends CustomPainter {
  final int h, m;
  final bool night;
  _ClockPainter(this.h, this.m, this.night);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    const c = Offset(100, 100);
    final face = night ? const Color(0xFF1E2A4A) : Colors.white;
    final majorTick = night ? const Color(0xFFA5B4FC) : const Color(0xFF7C5CFF);
    final minorTick = night ? const Color(0xFF46538A) : const Color(0xFFD5CDFA);
    final numbers = night ? const Color(0xFFF1F5F9) : const Color(0xFF2D2A45);
    final hourHand = night ? const Color(0xFFF8FAFC) : const Color(0xFF2D2A45);

    canvas.drawCircle(c, 94, Paint()..color = face);
    canvas.drawCircle(
      c,
      94,
      Paint()
        ..color = const Color(0xFF7C5CFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final a = i * 6 * pi / 180;
      final r1 = major ? 78.0 : 84.0, r2 = 88.0;
      canvas.drawLine(
        Offset(100 + r1 * sin(a), 100 - r1 * cos(a)),
        Offset(100 + r2 * sin(a), 100 - r2 * cos(a)),
        Paint()
          ..color = major ? majorTick : minorTick
          ..strokeWidth = major ? 3 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var n = 1; n <= 12; n++) {
      final a = n * 30 * pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: "$n",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: numbers,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          100 + 64 * sin(a) - tp.width / 2,
          100 - 64 * cos(a) - tp.height / 2,
        ),
      );
    }

    void hand(double deg, double length, double width, Color color) {
      final a = deg * pi / 180;
      canvas.drawLine(
        c,
        Offset(100 + length * sin(a), 100 - length * cos(a)),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    hand(((h % 12) + m / 60) * 30, 38, 8, hourHand);
    hand(m * 6.0, 66, 5, const Color(0xFFFF6B81));
    canvas.drawCircle(c, 6, Paint()..color = const Color(0xFFFF9F43));
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.h != h || old.m != m || old.night != night;
}

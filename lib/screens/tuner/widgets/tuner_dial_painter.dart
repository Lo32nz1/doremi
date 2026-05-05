import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dibuja el dial de afinación con arco, aguja animada y zonas de color.
///
/// Recibe:
/// - [centsOff] en [-50, 50]
/// - [needleColor] que ya viene interpolado por el padre
/// - [isInTune] para activar el resplandor central
/// - [glowProgress] valor animado [0,1] para el pulso de "afinado"
class TunerDialPainter extends CustomPainter {
  final double centsOff;
  final Color needleColor;
  final Color arcColor;
  final bool isInTune;
  final double glowProgress; // 0 → 1 para el pulso

  const TunerDialPainter({
    required this.centsOff,
    required this.needleColor,
    required this.arcColor,
    required this.isInTune,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = size.width * 0.42;

    _drawGlowIfInTune(canvas, center, radius);
    _drawArcBackground(canvas, center, radius);
    _drawGreenZone(canvas, center, radius);
    _drawTickMarks(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterPivot(canvas, center);
  }

  // ── Resplandor suave cuando está afinado ─────────────────────────────────

  void _drawGlowIfInTune(Canvas canvas, Offset center, double radius) {
    if (!isInTune || glowProgress <= 0) return;

    final glowRadius = radius * (0.6 + glowProgress * 0.5);
    final opacity = (0.25 * (1.0 - glowProgress)).clamp(0.0, 1.0);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.green.withValues(alpha: opacity),
          Colors.green.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, glowRadius, paint);
  }

  // ── Arco de fondo ────────────────────────────────────────────────────────

  void _drawArcBackground(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = arcColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,      // 180° (izquierda)
      math.pi,      // 180° de barrido
      false,
      paint,
    );
  }

  // ── Zona verde central (±10 cents) ──────────────────────────────────────

  void _drawGreenZone(Canvas canvas, Offset center, double radius) {
    // La zona "afinada" ocupa ±10/50 = 20% del arco = 36°
    const sweepFraction = 10.0 / 50.0; // ±10 cents de los ±50 del arco
    final sweepAngle = math.pi * sweepFraction; // en cada lado

    final paint = Paint()
      ..color = Colors.green.withValues(alpha: isInTune ? 0.55 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Dibujar centrado en 270° (parte superior del arco → posición 0 cents)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.5 - sweepAngle, // inicio (un poco a la izquierda del centro)
      sweepAngle * 2,              // barrido
      false,
      paint,
    );
  }

  // ── Tick marks ───────────────────────────────────────────────────────────

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    // 11 marcas: -50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50
    for (int i = 0; i <= 10; i++) {
      final fraction = i / 10.0; // 0 → 1
      final angle = math.pi + fraction * math.pi; // π → 2π (semicírculo)
      final isCenter = i == 5;
      final isMajor = i % 5 == 0;

      final innerR = radius - (isCenter ? 22 : isMajor ? 18 : 12);
      final outerR = radius + 2.0;

      final paint = Paint()
        ..color = isCenter
            ? Colors.green.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: isMajor ? 0.5 : 0.25)
        ..strokeWidth = isCenter ? 2.5 : isMajor ? 1.5 : 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final cos = math.cos(angle);
      final sin = math.sin(angle);
      canvas.drawLine(
        Offset(center.dx + innerR * cos, center.dy + innerR * sin),
        Offset(center.dx + outerR * cos, center.dy + outerR * sin),
        paint,
      );
    }
  }

  // ── Aguja ────────────────────────────────────────────────────────────────

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    // Mapear centsOff [-50, 50] → ángulo [π, 2π]
    final fraction = (centsOff + 50.0) / 100.0; // 0 a 1
    final angle = math.pi + fraction * math.pi;

    final needleLength = radius - 10;
    final tipX = center.dx + needleLength * math.cos(angle);
    final tipY = center.dy + needleLength * math.sin(angle);

    // Sombra sutil de la aguja
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(tipX + 2, tipY + 2),
      shadowPaint,
    );

    // Aguja principal
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, Offset(tipX, tipY), needlePaint);

    // Punta brillante
    final tipPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 4.5, tipPaint);
  }

  // ── Pivote central ───────────────────────────────────────────────────────

  void _drawCenterPivot(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      7,
      Paint()..color = needleColor,
    );
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(TunerDialPainter old) =>
      old.centsOff != centsOff ||
      old.needleColor != needleColor ||
      old.arcColor != arcColor ||
      old.isInTune != isInTune ||
      old.glowProgress != glowProgress;
}

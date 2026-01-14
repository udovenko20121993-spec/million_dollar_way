import 'dart:math' as math;
import 'package:flutter/material.dart';

class MidasGoldenCore extends StatefulWidget {
  final bool isThinking;
  const MidasGoldenCore({super.key, this.isThinking = false});

  @override
  State<MidasGoldenCore> createState() => _MidasGoldenCoreState();
}

class _MidasGoldenCoreState extends State<MidasGoldenCore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity, // Розтягуємо на всю ширину
          height: double.infinity, // Розтягуємо на всю висоту
          child: CustomPaint(
            painter: GoldenLiquidPainter(_controller.value, widget.isThinking),
          ),
        );
      },
    );
  }
}

class GoldenLiquidPainter extends CustomPainter {
  final double animationValue;
  final bool isThinking;
  GoldenLiquidPainter(this.animationValue, this.isThinking);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // РОБИМО РАДІУС ВЕЛИКИМ: 40% від найменшої сторони екрана
    final baseRadius =
        (size.width < size.height ? size.width : size.height) * 0.4;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700), // Яскраве золото
          const Color(0xFFB8860B).withOpacity(0.8), // Темне золото
          Colors.transparent,
        ],
        stops: const [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.5));

    final path = Path();
    for (var i = 0; i <= 360; i += 2) {
      final radians = i * math.pi / 180;

      // Анімація хвиль (рідке золото)
      final amplitude = isThinking ? 25.0 : 15.0;
      final noise =
          math.sin(radians * 4 + animationValue * math.pi * 2) * amplitude +
          math.cos(radians * 2 - animationValue * math.pi * 2) *
              (amplitude / 2);

      final r = baseRadius + noise;
      final x = center.dx + r * math.cos(radians);
      final y = center.dy + r * math.sin(radians);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Додаємо розмиття для ефекту світіння
    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, baseRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

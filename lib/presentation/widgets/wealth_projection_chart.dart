import 'package:flutter/material.dart';
import '../../domain/models/midas_models.dart';
import '../../services/midas_calculation_service.dart';

class WealthProjectionChart extends StatelessWidget {
  final WealthProjection projection;
  final MidasCalculationService service;

  const WealthProjectionChart({
    super.key,
    required this.projection,
    MidasCalculationService? service,
  }) : service = service ?? const MidasCalculationService();

  @override
  Widget build(BuildContext context) {
    if (projection.monthlyProjections.isEmpty) {
      return const Center(
        child: Text(
          'Немає даних для проєкції',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: WealthProjectionPainter(
        projections: projection.monthlyProjections,
        targetMillion: 1000000.0,
      ),
    );
  }
}

class WealthProjectionPainter extends CustomPainter {
  final List<MonthlyProjection> projections;
  final double targetMillion;

  WealthProjectionPainter({
    required this.projections,
    required this.targetMillion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.amber.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final targetLinePaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final maxValue = projections
        .map((p) => p.projectedValue)
        .reduce((a, b) => a > b ? a : b);
    const padding = 40.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;

    // Малюємо лінію цілі (\$1M)
    final targetY = padding + chartHeight * (1 - targetMillion / maxValue);
    canvas.drawLine(
      Offset(padding, targetY),
      Offset(size.width - padding, targetY),
      targetLinePaint,
    );

    // Малюємо підпис цілі
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '\$1M',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - padding - 30, targetY - 15));

    if (projections.length < 2) return;

    final points = <Offset>[];
    final fillPoints = <Offset>[];

    for (int i = 0; i < projections.length; i++) {
      final x = padding + (i / (projections.length - 1)) * chartWidth;
      final y =
          padding +
          chartHeight * (1 - projections[i].projectedValue / maxValue);
      final point = Offset(x, y);
      points.add(point);
      fillPoints.add(point);
    }

    // Малюємо заливку
    fillPoints.add(Offset(size.width - padding, size.height - padding));
    fillPoints.add(Offset(padding, size.height - padding));
    fillPoints.add(fillPoints.first);

    final path = Path();
    path.moveTo(fillPoints[0].dx, fillPoints[0].dy);
    for (int i = 1; i < fillPoints.length; i++) {
      path.lineTo(fillPoints[i].dx, fillPoints[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);

    // Малюємо лінію
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, paint);

    // Малюємо точки
    for (int i = 0; i < points.length; i += 12) {
      // Кожну 12-ту місяць
      canvas.drawCircle(
        points[i],
        4.0,
        Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.fill,
      );

      // Підписи років
      if (i > 0) {
        final yearText = TextPainter(
          text: TextSpan(
            text: '${(i / 12).toStringAsFixed(0)}р',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        yearText.layout();
        yearText.paint(canvas, Offset(points[i].dx - 10, size.height - 20));
      }
    }

    // Початкова точка
    canvas.drawCircle(
      points.first,
      6.0,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill,
    );

    // Кінцева точка
    canvas.drawCircle(
      points.last,
      6.0,
      Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

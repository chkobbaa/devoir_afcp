import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auth/absence.dart';

class CurveChartWidget extends StatelessWidget {
  final List<TotalAbsence> totals;

  const CurveChartWidget({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const Center(child: Text("Aucune absence à afficher."));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Courbe des absences par matière",
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _CurveChartPainter(totals: totals),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Total NHA (Heures d'absence)",
                  style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurveChartPainter extends CustomPainter {
  final List<TotalAbsence> totals;

  _CurveChartPainter({required this.totals});

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 45.0;
    const double bottomPadding = 35.0;
    const double topPadding = 25.0;
    const double rightPadding = 25.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Find max value
    double maxVal = totals.fold<double>(0.0, (prev, e) => max(prev, e.totalNha));
    if (maxVal == 0) maxVal = 10;
    // Round max to nice ceiling
    maxVal = (maxVal * 1.2).ceilToDouble();

    // Draw grid & Y-axis labels
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.0;

    const int yDivisions = 4;
    for (int i = 0; i <= yDivisions; i++) {
      final double yRatio = i / yDivisions;
      final double y = topPadding + chartHeight * (1 - yRatio);
      final double val = maxVal * yRatio;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Y-axis label
      final textSpan = TextSpan(
        text: val.toStringAsFixed(1),
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Axes
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    // Compute point offsets
    final List<Offset> points = [];
    final double stepX = totals.length > 1
        ? chartWidth / (totals.length - 1)
        : chartWidth / 2;

    for (int i = 0; i < totals.length; i++) {
      final double x = totals.length > 1
          ? leftPadding + i * stepX
          : leftPadding + chartWidth / 2;
      final double yRatio = totals[i].totalNha / maxVal;
      final double y = topPadding + chartHeight * (1 - yRatio);
      points.add(Offset(x, y));

      // X-axis label
      final textSpan = TextSpan(
        text: totals[i].codMat,
        style: const TextStyle(
          color: Colors.purple,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topPadding + chartHeight + 8),
      );
    }

    // Draw smooth curve using cubic bezier path
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlX1 = current.dx + (next.dx - current.dx) / 2;
        final controlY1 = current.dy;
        final controlX2 = current.dx + (next.dx - current.dx) / 2;
        final controlY2 = next.dy;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, next.dx, next.dy);
      }

      // Fill area under curve
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, topPadding + chartHeight)
        ..lineTo(points.first.dx, topPadding + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.withOpacity(0.35),
            Colors.purple.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));

      canvas.drawPath(fillPath, fillPaint);

      // Stroke curve line
      final linePaint = Paint()
        ..color = Colors.purple
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);

      // Draw point markers and value badges
      final dotPaint = Paint()..color = Colors.purple;
      final dotInnerPaint = Paint()..color = Colors.white;

      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        canvas.drawCircle(p, 6, dotPaint);
        canvas.drawCircle(p, 3.5, dotInnerPaint);

        // Value text above dot
        final valSpan = TextSpan(
          text: "${totals[i].totalNha}h",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final valPainter = TextPainter(
          text: valSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        valPainter.paint(
          canvas,
          Offset(p.dx - valPainter.width / 2, p.dy - valPainter.height - 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurveChartPainter oldDelegate) => true;
}

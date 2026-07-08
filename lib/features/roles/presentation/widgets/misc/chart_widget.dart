import 'package:flutter/material.dart';
import '../../../../../core/constants/app_color.dart';

class ChartWidget extends StatelessWidget {
  final List<int> data;
  final List<String> labels;
  const ChartWidget({
    super.key,
    required this.data,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartPainter(data: data, months: labels),
      size: const Size(double.infinity, 200),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> months;

  ChartPainter({required this.data, required this.months});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final padding = 30.0;
    final chartHeight = size.height - padding * 2;
    final chartWidth = size.width - padding * 2;
    final spacing = chartWidth / (data.length - 1);

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    final areaPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final areaPath = Path()
      ..moveTo(padding, size.height - padding);

    for (int i = 0; i < data.length; i++) {
      final x = padding + spacing * i;
      final y = padding + chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        areaPath.lineTo(x, y);
      } else {
        areaPath.quadraticBezierTo(
          padding + spacing * (i - 1) + spacing / 2,
          padding + chartHeight -
              ((data[i - 1] + data[i]) / 2 / maxValue) * chartHeight,
          x,
          y,
        );
      }
    }

    areaPath.lineTo(padding + spacing * (data.length - 1), size.height - padding);
    areaPath.close();
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + spacing * i;
      final y = padding + chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.quadraticBezierTo(
          padding + spacing * (i - 1) + spacing / 2,
          padding + chartHeight -
              ((data[i - 1] + data[i]) / 2 / maxValue) * chartHeight,
          x,
          y,
        );
      }
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < data.length; i++) {
      final x = padding + spacing * i;
      final y = padding + chartHeight - (data[i] / maxValue) * chartHeight;

      canvas.drawCircle(Offset(x, y), 6, dotPaint);
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()..color = AppColors.primary.withValues(alpha: 0.3),
      );

      final valueText = TextSpan(
        text: data[i].toString(),
        style: textStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      );
      final textPainter = TextPainter(
        text: valueText,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - 24),
      );

      if (i < months.length) {
        final monthText = TextSpan(
          text: months[i],
          style: textStyle,
        );
        final monthPainter = TextPainter(
          text: monthText,
          textDirection: TextDirection.ltr,
        );
        monthPainter.layout();
        monthPainter.paint(
          canvas,
          Offset(x - monthPainter.width / 2, size.height - padding + 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.months != months;
}

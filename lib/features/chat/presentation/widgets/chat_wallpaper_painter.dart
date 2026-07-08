import 'package:flutter/material.dart';
import '../../../../core/constants/app_color.dart';

class ChatWallpaperPainter extends CustomPainter {
  ChatWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const cellW = 140.0;
    const cellH = 130.0;
    final cols = (size.width / cellW).ceil() + 1;
    final rows = (size.height / cellH).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dx = c * cellW + ((c + r).isEven ? 20.0 : -20.0);
        final dy = r * cellH + ((c * 7 + r * 13) % 3) * 15.0;
        final index = (c + r) % 4;
        _drawIcon(canvas, index, dx, dy, paint);
      }
    }
  }

  void _drawIcon(Canvas canvas, int index, double x, double y, Paint paint) {
    canvas.save();
    canvas.translate(x, y);

    switch (index) {
      case 0:
        _drawPlus(canvas, paint);
      case 1:
        _drawPill(canvas, paint);
      case 2:
        _drawPulse(canvas, paint);
      case 3:
        _drawStethoscope(canvas, paint);
    }

    canvas.restore();
  }

  void _drawPlus(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(0, -10)
      ..lineTo(0, 10)
      ..moveTo(-10, 0)
      ..lineTo(10, 0);
    canvas.drawPath(path, paint);
  }

  void _drawPill(Canvas canvas, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), paint);
  }

  void _drawPulse(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(-16, 0)
      ..lineTo(-10, 0)
      ..lineTo(-6, -8)
      ..lineTo(-2, 8)
      ..lineTo(2, -8)
      ..lineTo(6, 0)
      ..lineTo(16, 0);
    canvas.drawPath(path, paint);
  }

  void _drawStethoscope(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(0, -8), 6, paint);
    final tube = Path()
      ..moveTo(0, -2)
      ..lineTo(0, 4)
      ..lineTo(-6, 10)
      ..moveTo(0, 4)
      ..lineTo(6, 10);
    canvas.drawPath(tube, paint);
  }

  @override
  bool shouldRepaint(ChatWallpaperPainter oldDelegate) => false;
}

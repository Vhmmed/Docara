import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';

class AppRingSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const AppRingSpinner({
    super.key,
    this.size = 44,
    this.color = AppColors.primary,
  });

  @override
  State<AppRingSpinner> createState() => _AppRingSpinnerState();
}

class _AppRingSpinnerState extends State<AppRingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _controller.value * 2 * pi,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _RingPainter(color: widget.color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;

  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    paint.color = color.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      210 * pi / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}

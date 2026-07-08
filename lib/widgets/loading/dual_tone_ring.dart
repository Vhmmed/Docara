import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';

class AppDualToneRing extends StatefulWidget {
  final double size;
  final Color color;

  const AppDualToneRing({
    super.key,
    this.size = 44,
    this.color = AppColors.primary,
  });

  @override
  State<AppDualToneRing> createState() => _AppDualToneRingState();
}

class _AppDualToneRingState extends State<AppDualToneRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _rotationAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
      angle: _rotationAnim.value * 2 * pi,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _DualTonePainter(color: widget.color),
      ),
    );
  }
}

class _DualTonePainter extends CustomPainter {
  final Color color;

  _DualTonePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = color.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius, paint);

    // Primary arc — 180°
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi,
      false,
      paint,
    );

    // Secondary arc — 90° lighter
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi / 2,
      pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DualTonePainter old) => old.color != color;
}

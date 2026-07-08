import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';

class AppBouncingDots extends StatefulWidget {
  final double size;
  final Color color;

  const AppBouncingDots({
    super.key,
    this.size = 20,
    this.color = AppColors.primary,
  });

  @override
  State<AppBouncingDots> createState() => _AppBouncingDotsState();
}

class _AppBouncingDotsState extends State<AppBouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
    return SizedBox(
      width: widget.size * 3.5,
      height: widget.size + 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final t = (_controller.value * 3 - i * 0.15).clamp(0.0, 1.0);
          final phase = (t * 2 * 3.14159);
          final offset = sin(phase) * 6;
          return Transform.translate(
            offset: Offset(0, -offset),
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

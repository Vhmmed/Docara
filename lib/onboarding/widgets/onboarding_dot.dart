import 'package:flutter/material.dart';

class OnboardingDot extends StatelessWidget {
  final bool isActive;
  final Color activeColor;

  const OnboardingDot({
    super.key,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: isActive ? 30 : 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? activeColor : Colors.grey.shade300,
      ),
    );
  }
}
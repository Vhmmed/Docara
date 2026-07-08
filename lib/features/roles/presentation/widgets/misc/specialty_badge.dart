import 'package:flutter/material.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class SpecialtyBadge extends StatelessWidget {
  final String label;
  const SpecialtyBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff8FBAC7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        text: label,
        size: 12,
        color: const Color(0xff8FBAC7),
        
        weight: FontWeight.w600,
      ),
    );
  }
}

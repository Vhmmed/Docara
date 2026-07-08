import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class InfoBanner extends StatelessWidget {
  final String message;
  const InfoBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info,
            color: Colors.orange,
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: CustomText(
              text: message,
              size: 12,
              color: Colors.grey,
              
            ),
          ),
        ],
      ),
    );
  }
}

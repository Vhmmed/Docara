import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class AdminSecurityNotice extends StatelessWidget {
  const AdminSecurityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const Gap(10),
          Expanded(
            child: CustomText(
              text:
                  'Admin access is restricted. All actions are logged for security.',
              size: 12,
              
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

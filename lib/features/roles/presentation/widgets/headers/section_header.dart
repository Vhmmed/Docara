import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool showChevron;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomText(
          text: title,
          size: 18,
          color: Colors.black,
          
          weight: FontWeight.w700,
        ),
        const Spacer(),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                CustomText(
                  text: actionText!,
                  size: 14,
                  color: const Color(0xff8FBAC7),
                  
                  weight: FontWeight.w600,
                ),
                if (showChevron) ...[
                  const Gap(4),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: Color(0xff8FBAC7),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

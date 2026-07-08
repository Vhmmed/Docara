import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class AppointmentCard extends StatelessWidget {
  final String title;
  final String time;
  final Color themeColor;
  final IconData icon;
  final String typeLabel;
  const AppointmentCard({
    super.key,
    required this.title,
    required this.time,
    this.themeColor = const Color(0xff8FBAC7),
    this.icon = CupertinoIcons.video_camera,
    this.typeLabel = 'video',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: themeColor,
              size: 22,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  size: 15,
                  color: Colors.black,
                  
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const Gap(4),
                    CustomText(
                      text: time,
                      size: 13,
                      color: Colors.grey,
                      
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomText(
                        text: typeLabel,
                        size: 10,
                        color: themeColor,
                        
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }
}

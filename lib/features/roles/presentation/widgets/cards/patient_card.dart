import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class PatientCard extends StatelessWidget {
  final String initial;
  final String name;
  final String ageGender;
  final String lastVisitDate;
  final String? avatarUrl;
  const PatientCard({
    super.key,
    required this.initial,
    required this.name,
    required this.ageGender,
    required this.lastVisitDate,
    this.avatarUrl,
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
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xff8FBAC7).withOpacity(0.1),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? CustomText(
                    text: initial,
                    size: 18,
                    color: const Color(0xff8FBAC7),
                    
                    weight: FontWeight.w700,
                  )
                : null,
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: name,
                  size: 16,
                  color: Colors.black,
                  
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                CustomText(
                  text: ageGender,
                  size: 13,
                  color: Colors.grey,
                  
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const CustomText(
                  text: 'Last visit',
                  size: 10,
                  color: Colors.grey,
                  
                ),
              ),
              const Gap(5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomText(
                  text: lastVisitDate,
                  size: 14,
                  color: Colors.black,

                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

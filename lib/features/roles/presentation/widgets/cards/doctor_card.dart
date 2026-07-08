import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_text_styles.dart';

class DoctorCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String info1;
  final String info2;
  final String? avatarUrl;
  final bool isDoctor;
  final VoidCallback onTap;
  final VoidCallback? onMessageTap;

  const DoctorCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.info1,
    required this.info2,
    this.avatarUrl,
    required this.isDoctor,
    required this.onTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: isDoctor
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1),
                    child: Icon(
                      isDoctor ? Icons.medical_services : CupertinoIcons.person,
                      color: isDoctor ? AppColors.primary : AppColors.info,
                      size: 24,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDoctor ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (info1.isNotEmpty || info2.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (info1.isNotEmpty) _buildInfoChip(info1),
                        if (info2.isNotEmpty) _buildInfoChip(info2),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onMessageTap != null)
              GestureDetector(
                onTap: onMessageTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    CupertinoIcons.chat_bubble_2,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
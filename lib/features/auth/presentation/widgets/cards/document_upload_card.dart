import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String uploadedSubtitle;
  final bool uploaded;
  final VoidCallback onTap;
  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.uploadedSubtitle,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded ? const Color(0xff8FBAC7) : Colors.grey.shade200,
            width: uploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xff8FBAC7).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.doc_text,
                color: uploaded ? const Color(0xff8FBAC7) : Colors.grey[500],
                size: 24,
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    size: 14,
                    color: Colors.black87,
                    
                    weight: FontWeight.w600,
                  ),
                  const Gap(2),
                  CustomText(
                    text: uploaded ? uploadedSubtitle : subtitle,
                    size: 12,
                    color: uploaded ? Colors.green : Colors.grey[500],
                    
                  ),
                ],
              ),
            ),
            Icon(
              uploaded
                  ? CupertinoIcons.checkmark_circle
                  : CupertinoIcons.cloud_upload,
              color: uploaded ? Colors.green : const Color(0xff8FBAC7),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

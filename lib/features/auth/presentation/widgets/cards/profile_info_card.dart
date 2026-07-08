import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../../../data/models/role_model.dart';
import '../misc/profile_image_picker.dart';

class ProfileInfoCard extends StatelessWidget {
  final String? userName;
  final String? avatarUrl;
  final bool isUploading;
  final String roleId;
  final RoleModel currentRole;
  final VoidCallback onPickImage;
  final String? specialtyName;
  final String? clinicAddress;
  final bool? isVerified;
  final String? verificationStatus;

  const ProfileInfoCard({
    super.key,
    this.userName,
    this.avatarUrl,
    required this.isUploading,
    required this.roleId,
    required this.currentRole,
    required this.onPickImage,
    this.specialtyName,
    this.clinicAddress,
    this.isVerified,
    this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = roleId == 'doctor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xff8FBAC7).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isUploading
              ? const SizedBox(
                  width: 70,
                  height: 70,
                  child: Center(child: AppRingSpinner(size: 24)),
                )
              : ProfileImagePicker(
                  imagePath: null,
                  imageUrl: avatarUrl,
                  onTap: onPickImage,
                  radius: 35,
                ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: isDoctor ? 'Dr. $userName' : (userName ?? ''),
                  size: 18,
                  color: Colors.black,
                  weight: FontWeight.w600,
                ),
                if (isDoctor && specialtyName != null) ...[
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xff8FBAC7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      text: specialtyName!,
                      size: 14,
                      color: const Color(0xff8FBAC7),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
                const Gap(4),
                if (isDoctor && clinicAddress != null) ...[
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location,size: 13,),
                      const Gap(2),
                      CustomText(
                        text: clinicAddress!,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
                if (isDoctor) ...[
                  const Gap(8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isVerified == true
                                  ? Colors.green
                                  : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText(
                          text: isVerified == true
                              ? 'Verified'
                              : verificationStatus == 'approved'
                                  ? 'Verified'
                                  : verificationStatus == 'rejected'
                                      ? 'Rejected'
                                      : 'Pending',
                          size: 10,
                          color: isVerified == true
                              ? Colors.green
                              : Colors.orange,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: currentRole.color?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText(
                          text: currentRole.id.toUpperCase(),
                          size: 10,
                          color: currentRole.color,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Gap(4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: currentRole.color?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      text: currentRole.id.toUpperCase(),
                      size: 10,
                      color: currentRole.color,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

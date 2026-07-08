import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_text_styles.dart';

class DoctorDetailSheet extends StatelessWidget {
  final String name;
  final String specialty;
  final String experience;
  final String location;
  final String bio;
  final String fee;
  final String avatarUrl;
  final String? profilesAvatarUrl;
  final String licensePath;
  final String certificatePath;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const DoctorDetailSheet({
    super.key,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.location,
    required this.bio,
    required this.fee,
    required this.avatarUrl,
    this.profilesAvatarUrl,
    required this.licensePath,
    required this.certificatePath,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isLicenceMocked = licensePath.startsWith('PENDING_UPLOAD/');
    final isCertMocked = certificatePath.startsWith('PENDING_UPLOAD/');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : (profilesAvatarUrl != null && profilesAvatarUrl!.isNotEmpty
                            ? NetworkImage(profilesAvatarUrl!)
                            : null),
                    child: avatarUrl.isEmpty
                        ? (profilesAvatarUrl == null || profilesAvatarUrl!.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 22,
                                ),
                              )
                            : null)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            specialty,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section('Professional Information'),
              const SizedBox(height: 8),
              _infoRow(Icons.work_outline, 'Experience', experience),
              _infoRow(CupertinoIcons.location, 'Clinic', location),
              _infoRow(Icons.attach_money, 'Consultation Fee', '\$$fee'),
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    bio,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _section('Documents'),
              const SizedBox(height: 8),
              _docTile('Medical License', licensePath, isLicenceMocked, context),
              const SizedBox(height: 6),
              _docTile('Board Certificate', certificatePath, isCertMocked, context),
              if (isLicenceMocked || isCertMocked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Document uploads are currently mocked — review from DB or Supabase Storage directly.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(String path, BuildContext context) async {
    if (path.startsWith('PENDING_UPLOAD/')) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document not yet uploaded by doctor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (path.isEmpty) return;

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('documents')
          .createSignedUrl(path, 60);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open document.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _docTile(String label, String path, bool isMocked, BuildContext context) {
    return GestureDetector(
      onTap: () => _openDocument(path, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              isMocked ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              size: 18,
              color: isMocked ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    path.isNotEmpty ? path : 'Not uploaded',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

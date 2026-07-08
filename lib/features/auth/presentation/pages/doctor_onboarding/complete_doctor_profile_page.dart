import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storage_client/storage_client.dart';
import 'package:logging/logging.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../widgets/cards/document_upload_card.dart';
import '../../widgets/misc/info_banner.dart';
import '../../widgets/misc/profile_image_picker.dart';
import 'doctor_waiting_approval_page.dart';

class CompleteDoctorProfilePage extends StatefulWidget {
  final String userId;
  final String? specialtyId;
  const CompleteDoctorProfilePage({
    super.key,
    required this.userId,
    this.specialtyId,
  });

  @override
  State<CompleteDoctorProfilePage> createState() =>
      _CompleteDoctorProfilePageState();
}

class _CompleteDoctorProfilePageState
    extends State<CompleteDoctorProfilePage> {
  final TextEditingController clinicAddressController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _profileImage;
  PlatformFile? _licenseFile;
  PlatformFile? _certificateFile;
  bool _isLoading = false;
  static const bool _debugUploads = false;

  @override
  void dispose() {
    clinicAddressController.dispose();
    experienceController.dispose();
    bioController.dispose();
    feeController.dispose();
    super.dispose();
  }

  String? _validateClinicAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter clinic address';
    return null;
  }

  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter years of experience';
    final exp = int.tryParse(value.trim());
    if (exp == null || exp < 0) return 'Please enter a valid number';
    return null;
  }

  String? _validateBio(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a short bio';
    return null;
  }

  String? _validateFee(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter consultation fee';
    final fee = double.tryParse(value.trim());
    if (fee == null || fee <= 0) return 'Please enter a valid positive number';
    return null;
  }

  Future<void> _pickProfileImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final fileSizeMB = File(picked.path).lengthSync() / 1048576;
      if (fileSizeMB > 5) {
        if (!mounted) return;
        CustomSnackBarHelper.show(
          context,
          message: 'Profile image must be under 5MB',
          isSuccess: false,
        );
        return;
      }

      setState(() => _profileImage = picked);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to pick image',
        isSuccess: false,
      );
    }
  }

  Future<void> _pickLicense() => _pickDocument((f) => _licenseFile = f);

  Future<void> _pickCertificate() => _pickDocument((f) => _certificateFile = f);

  Future<void> _pickDocument(void Function(PlatformFile) onPicked) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 10 * 1048576) {
        if (!mounted) return;
        CustomSnackBarHelper.show(
          context,
          message: 'Documents must be under 10MB',
          isSuccess: false,
        );
        return;
      }

      setState(() => onPicked(file));
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to pick file',
        isSuccess: false,
      );
    }
  }

  String _ext(String path) => path.split('.').last.toLowerCase();

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final specialtyId = widget.specialtyId;
    if (specialtyId == null || specialtyId.isEmpty) {
      CustomSnackBarHelper.show(
        context,
        message: 'Please select your specialization first',
        isSuccess: false,
      );
      return;
    }

    if (_profileImage == null) {
      CustomSnackBarHelper.show(
        context,
        message: 'Please select a profile photo',
        isSuccess: false,
      );
      return;
    }

    if (_licenseFile == null || _certificateFile == null) {
      CustomSnackBarHelper.show(
        context,
        message: 'Please upload all required documents',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_debugUploads) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        if (record.loggerName == 'supabase.storage') {
          debugPrint('>>> [STORAGE_HTTP] ${record.message}');
        }
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final userId = widget.userId;
      final auth = supabase.auth;
      final session = auth.currentSession;
      final accessToken = session?.accessToken;
      if (_debugUploads) {
        debugPrint('>>> [UPLOAD] userId=$userId, '
            'hasSession=${session != null}, '
            'currentUser=${auth.currentUser?.id}');

        if (accessToken != null) {
          final parts = accessToken.split('.');
          if (parts.length == 3) {
            try {
              final payload = utf8.decode(
                base64Url.decode(base64Url.normalize(parts[1])),
              );
              debugPrint('>>> [JWT_PAYLOAD] $payload');
            } catch (_) {
              debugPrint('>>> [JWT_PAYLOAD] (failed to decode)');
            }
          }
        }

        final expiresAt = session?.expiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        debugPrint('>>> [TOKEN_EXPIRY] expiresAt=$expiresAt, '
            'now=$now, '
            'expired=${expiresAt != null && expiresAt < now}');
      }

      // Upload profile picture
      final profileImage = _profileImage!;
      final imgExt = _ext(profileImage.path);
      final avatarPath = '$userId/profile.$imgExt';
      if (_debugUploads) {
        final avatarContentType = _mimeType(imgExt);
        final avatarFileSize = File(profileImage.path).lengthSync();
        debugPrint('>>> [UPLOAD_START] bucket=avatars, path=$avatarPath, '
            'at=${DateTime.now().toIso8601String()}, '
            'tokenPrefix=${accessToken?.substring(0, 15) ?? "null"}, '
            'contentType=$avatarContentType, '
            'fileSize=$avatarFileSize, '
            'method=upload(File), '
            'xfilePath=${profileImage.path}');
      }
      try {
        await supabase.storage.from('avatars').upload(
          avatarPath,
          File(profileImage.path),
          fileOptions: FileOptions(
            contentType: _mimeType(imgExt),
            upsert: true,
          ),
        );
        if (_debugUploads) {
          debugPrint('>>> [UPLOAD_END] bucket=avatars, '
              'at=${DateTime.now().toIso8601String()}');
        }
      } catch (e) {
        if (_debugUploads) {
          debugPrint('>>> [UPLOAD_ERROR] bucket=avatars, path=$avatarPath, '
              'exception=$e');
          if (e is StorageException) {
            debugPrint('>>> [UPLOAD_ERROR_DETAILS] bucket=avatars '
                'message="${e.message}", '
                'statusCode=${e.statusCode}, '
                'error=${e.error}');
          }
        }
        rethrow;
      }
      final avatarUrl =
          supabase.storage.from('avatars').getPublicUrl(avatarPath);

      // ============================================================
      // TEMPORARY MOCK — DOCUMENT UPLOAD DISABLED
      // Reason: persistent 403 RLS error on the SECOND sequential
      // Supabase Storage upload in the same session, reproduced across
      // multiple bucket names (documents, docfiles) — root cause not
      // yet found. Avatar upload (first in sequence) works fine.
      // TODO: revisit and restore real upload once root cause is found.
      // ============================================================
      final pendingLicensePath = 'PENDING_UPLOAD/$userId/license.pdf';
      final pendingCertPath = 'PENDING_UPLOAD/$userId/certificate.pdf';
      // ============================================================

      // Save to DB
      await supabase.from('doctors').upsert({
        'id': userId,
        'specialty_id': specialtyId,
        'bio': bioController.text.trim(),
        'clinic_address': clinicAddressController.text.trim(),
        'years_of_experience':
            int.tryParse(experienceController.text.trim()) ?? 0,
        'consultation_fee': double.parse(feeController.text.trim()),
        'is_verified': false,
        'status': 'pending',
        'avatar_url': avatarUrl,
        'license_path': pendingLicensePath,
        'certificate_path': pendingCertPath,
      });

      final profileResp = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final fullName = profileResp?['full_name'] as String? ?? 'User';

      await supabase.from('profiles').upsert({
        'id': userId,
        'role': 'doctor',
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;

      CustomSnackBarHelper.show(
        context,
        message: 'Profile submitted successfully!',
        isSuccess: true,
      );

      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DoctorWaitingApprovalPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Error submitting profile: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CustomText(
          text: 'Complete Profile',
          size: 20,
          
          weight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileImagePicker(
                imagePath: _profileImage?.path,
                onTap: _pickProfileImage,
              ),
              const Gap(30),
              const CustomText(
                text: 'Clinic Address',
                size: 15,
                
                weight: FontWeight.w600,
                color: Colors.black87,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: clinicAddressController,
                hint: 'Enter clinic address',
                isPassword: false,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateClinicAddress,
              ),
              const Gap(16),
              const CustomText(
                text: 'Years of Experience',
                size: 15,
                
                weight: FontWeight.w600,
                color: Colors.black87,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: experienceController,
                hint: 'e.g., 5',
                isPassword: false,
                keyboardType: TextInputType.number,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateExperience,
              ),
              const Gap(16),
              const CustomText(
                text: 'Short Bio',
                size: 15,
                
                weight: FontWeight.w600,
                color: Colors.black87,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: bioController,
                hint: 'Describe your expertise...',
                isPassword: false,
                maxLines: 3,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateBio,
              ),
              const Gap(16),
              const CustomText(
                text: 'Consultation Fee (EGP)',
                size: 15,
                
                weight: FontWeight.w600,
                color: Colors.black87,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: feeController,
                hint: 'e.g., 200',
                isPassword: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateFee,
              ),
              const Gap(24),
              const CustomText(
                text: 'Upload Documents',
                size: 18,
                
                weight: FontWeight.w700,
                color: Colors.black87,
              ),
              const Gap(16),
              DocumentUploadCard(
                title: 'Medical License',
                subtitle: 'Upload your medical license (PDF/Image)',
                uploadedSubtitle: _licenseFile?.name ?? '✅ Uploaded',
                uploaded: _licenseFile != null,
                onTap: _pickLicense,
              ),
              const Gap(12),
              DocumentUploadCard(
                title: 'Board Certificate',
                subtitle: 'Upload your board certificate (PDF/Image)',
                uploadedSubtitle: _certificateFile?.name ?? '✅ Uploaded',
                uploaded: _certificateFile != null,
                onTap: _pickCertificate,
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff8FBAC7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const AppPulseDot(
                          size: 20, color: Colors.white)
                      : const CustomText(
                          text: 'Submit for Approval',
                          size: 17,
                          color: Colors.white,
                          
                          weight: FontWeight.w600,
                        ),
                ),
              ),
              const Gap(20),
              const InfoBanner(
                message:
                    'Your documents will be reviewed by the admin. This usually takes 24-48 hours.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

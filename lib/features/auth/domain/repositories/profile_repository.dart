import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> fetchProfile();
  Future<String> uploadAvatar(String filePath);
  Future<void> updateAvatarUrl(String url);
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
  });
  Future<void> updateConsultationFee(double fee);
}

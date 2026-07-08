import 'dart:io';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client;

  ProfileRepositoryImpl(this._client);

  @override
  Future<ProfileEntity> fetchProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client
        .from('profiles')
        .select(
            'full_name, avatar_url, phone, date_of_birth, gender, blood_type, allergies, medical_conditions, role')
        .eq('id', userId)
        .single();

    List<String> _parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.cast<String>();
      return [];
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final role = response['role'] as String? ?? 'patient';
    String? specialtyName;
    String? clinicAddress;
    double? consultationFee;
    bool? isVerified;
    String? verificationStatus;
    int? patientCount;
    int? yearsOfExperience;

    if (role == 'doctor') {
      try {
        final docRow = await _client
            .from('doctors')
            .select(
                'specialty_id, clinic_address, consultation_fee, is_verified, status, years_of_experience')
            .eq('id', userId)
            .maybeSingle();

        if (docRow != null) {
          clinicAddress = docRow['clinic_address'] as String?;
          final fee = docRow['consultation_fee'];
          if (fee != null) consultationFee = (fee as num).toDouble();
          isVerified = docRow['is_verified'] as bool? ?? false;
          verificationStatus = docRow['status'] as String? ?? 'pending';
          yearsOfExperience = docRow['years_of_experience'] as int?;

          final specId = docRow['specialty_id'] as String?;
          if (specId != null) {
            final specRow = await _client
                .from('specialties')
                .select('name')
                .eq('id', specId)
                .maybeSingle();
            specialtyName = specRow?['name'] as String?;
          }
        }
      } catch (e) {
        developer.log('Failed to fetch doctor data', name: 'ProfileRepositoryImpl', error: e);
      }
    }

    return ProfileEntity(
      userId: userId,
      fullName: response['full_name'] as String?,
      avatarUrl: response['avatar_url'] as String?,
      role: role,
      phone: response['phone'] as String?,
      dateOfBirth: _parseDate(response['date_of_birth']),
      gender: response['gender'] as String?,
      bloodType: response['blood_type'] as String?,
      allergies: _parseList(response['allergies']),
      medicalConditions: _parseList(response['medical_conditions']),
      specialtyName: specialtyName,
      clinicAddress: clinicAddress,
      consultationFee: consultationFee,
      isVerified: isVerified,
      verificationStatus: verificationStatus,
      patientCount: patientCount,
      yearsOfExperience: yearsOfExperience,
    );
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final ext = filePath.split('.').last.toLowerCase();
    final avatarPath = '$userId/profile.$ext';

    await _client.storage.from('avatars').upload(
      avatarPath,
      File(filePath),
      fileOptions: FileOptions(
        contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
        upsert: true,
      ),
    );

    final url = _client.storage.from('avatars').getPublicUrl(avatarPath);

    await _client
        .from('profiles')
        .update({'avatar_url': url}).eq('id', userId);

    developer.log('Profile avatar uploaded', name: 'ProfileRepositoryImpl');
    return url;
  }

  @override
  Future<void> updateAvatarUrl(String url) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    await _client
        .from('profiles')
        .update({'avatar_url': url}).eq('id', userId);
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final Map<String, dynamic> payload = {};
    if (fullName != null) payload['full_name'] = fullName;
    if (phone != null) payload['phone'] = phone;
    if (dateOfBirth != null) {
      payload['date_of_birth'] =
          '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
    }
    if (gender != null) payload['gender'] = gender;
    if (bloodType != null) payload['blood_type'] = bloodType;
    if (allergies != null) payload['allergies'] = allergies;
    if (medicalConditions != null) payload['medical_conditions'] = medicalConditions;

    if (payload.isEmpty) return;

    await _client.from('profiles').update(payload).eq('id', userId);
  }

  @override
  Future<void> updateConsultationFee(double fee) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('doctors').update({'consultation_fee': fee}).eq('id', userId);
  }
}

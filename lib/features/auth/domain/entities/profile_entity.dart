import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;

  // Doctor-specific
  final String? specialtyName;
  final String? clinicAddress;
  final double? consultationFee;
  final bool? isVerified;
  final String? verificationStatus;
  final int? patientCount;
  final int? yearsOfExperience;

  const ProfileEntity({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.role = 'patient',
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.specialtyName,
    this.clinicAddress,
    this.consultationFee,
    this.isVerified,
    this.verificationStatus,
    this.patientCount,
    this.yearsOfExperience,
  });

  ProfileEntity copyWith({
    String? userId,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? specialtyName,
    String? clinicAddress,
    double? consultationFee,
    bool? isVerified,
    String? verificationStatus,
    int? patientCount,
    int? yearsOfExperience,
  }) {
    return ProfileEntity(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      specialtyName: specialtyName ?? this.specialtyName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      patientCount: patientCount ?? this.patientCount,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        avatarUrl,
        role,
        phone,
        dateOfBirth,
        gender,
        bloodType,
        allergies,
        medicalConditions,
        specialtyName,
        clinicAddress,
        consultationFee,
        isVerified,
        verificationStatus,
        patientCount,
        yearsOfExperience,
      ];
}

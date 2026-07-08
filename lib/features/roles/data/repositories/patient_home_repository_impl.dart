import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../appointments/data/appointment_service.dart';
import '../../domain/entities/patient_home_data.dart';
import '../../domain/repositories/patient_home_repository.dart';

class PatientHomeRepositoryImpl implements PatientHomeRepository {
  PatientHomeRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> getUserName(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      return response['full_name'] as String?;
    } catch (e) {
      developer.log('getUserName error: $e');
      return null;
    }
  }

  @override
  Future<PatientHomeData> getHomeData(String patientId) async {
    final results = await Future.wait([
      getUserName(patientId),
      AppointmentService.getPatientUpcomingAppointment(patientId),
      AppointmentService.getApprovedDoctors(),
    ]);

    final userName = results[0] as String?;
    final upcomingRaw = results[1] as Map<String, dynamic>?;

    UpcomingAppointmentData? upcoming;
    if (upcomingRaw != null) {
      upcoming = UpcomingAppointmentData(
        doctorName: upcomingRaw['doctorName'] as String? ?? 'Doctor',
        doctorAvatarUrl: upcomingRaw['doctorAvatarUrl'] as String?,
        specialty: upcomingRaw['specialty'] as String? ?? 'General',
        scheduledAt: upcomingRaw['scheduledAt'] as DateTime,
        status: upcomingRaw['status'] as String? ?? 'pending',
        type: upcomingRaw['type'] as String? ?? 'in_person',
      );
    }

    final doctorsRaw = (results[2] as List).cast<Map<String, dynamic>>();
    final doctors = doctorsRaw.map((d) {
      return DoctorInfo(
        id: d['id'] as String? ?? '',
        name: (d['profile']?['full_name'] as String?) ?? 'Doctor',
        specialty: (d['specialty']?['name'] as String?) ?? 'General',
        consultationFee: (d['consultation_fee'] as num?)?.toDouble(),
        clinicAddress: d['clinic_address'] as String?,
        avatarUrl: d['avatar_url'] as String?,
      );
    }).toList();

    return PatientHomeData(
      userName: userName,
      upcomingAppointment: upcoming,
      doctors: doctors,
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/patient_summary_entity.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../models/medical_record_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  MedicalRecordRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MedicalRecordEntity>> getPatientRecords(String patientId) async {
    final rows = await _client
        .from('medical_records')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => MedicalRecordModel.fromJson(r))
        .toList();
  }

  @override
  Future<void> createRecord({
    required String patientId,
    required String? doctorId,
    required RecordType recordType,
    required String title,
    String? chiefComplaints,
    String? diagnosis,
    String? prescription,
    DateTime? followUpDate,
    String? additionalInstructions,
    String? fileUrl,
  }) async {
    final model = MedicalRecordModel(
      id: '',
      patientId: patientId,
      doctorId: doctorId,
      recordType: recordType,
      title: title,
      chiefComplaints: chiefComplaints,
      diagnosis: diagnosis,
      prescription: prescription,
      followUpDate: followUpDate,
      additionalInstructions: additionalInstructions,
      fileUrl: fileUrl,
      createdAt: DateTime.now(),
    );
    await _client.from('medical_records').insert(model.toJson());
  }

  @override
  Future<List<MedicalRecordEntity>> getRecordsForDoctor(
    String doctorId,
    String patientId,
  ) async {
    final rows = await _client
        .from('medical_records')
        .select()
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => MedicalRecordModel.fromJson(r))
        .toList();
  }

  @override
  Future<PatientSummaryEntity> getPatientSummary(String patientId) async {
    final results = await Future.wait([
      // Profile data
      _client
          .from('profiles')
          .select(
              'full_name, avatar_url, date_of_birth, gender, blood_type, allergies, medical_conditions')
          .eq('id', patientId)
          .single(),
      // Visit count from medical_records
      _client
          .from('medical_records')
          .select('created_at')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false),
    ]);

    final profile = results[0] as Map<String, dynamic>;
    final records = (results[1] as List).cast<Map<String, dynamic>>();

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final monthStart = DateTime(now.year, now.month, 1);

    final totalVisits = records.length;
    final visitsThisYear = records
        .where((r) =>
            DateTime.parse(r['created_at'] as String).isAfter(yearStart))
        .length;
    final visitsThisMonth = records
        .where((r) =>
            DateTime.parse(r['created_at'] as String).isAfter(monthStart))
        .length;
    final lastVisitDate = records.isNotEmpty
        ? DateTime.parse(records.first['created_at'] as String)
        : null;

    List<String> parseJsonbList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.cast<String>();
      return [];
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PatientSummaryEntity(
      patientId: patientId,
      fullName: profile['full_name'] as String? ?? 'Unknown',
      avatarUrl: profile['avatar_url'] as String?,
      dateOfBirth: parseDate(profile['date_of_birth']),
      gender: profile['gender'] as String?,
      bloodType: profile['blood_type'] as String?,
      allergies: parseJsonbList(profile['allergies']),
      medicalConditions: parseJsonbList(profile['medical_conditions']),
      totalVisits: totalVisits,
      visitsThisYear: visitsThisYear,
      visitsThisMonth: visitsThisMonth,
      lastVisitDate: lastVisitDate,
    );
  }
}

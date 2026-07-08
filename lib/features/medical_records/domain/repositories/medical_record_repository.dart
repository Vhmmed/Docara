import '../entities/medical_record_entity.dart';
import '../entities/patient_summary_entity.dart';

abstract class MedicalRecordRepository {
  Future<List<MedicalRecordEntity>> getPatientRecords(String patientId);
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
  });
  Future<List<MedicalRecordEntity>> getRecordsForDoctor(
    String doctorId,
    String patientId,
  );
  Future<PatientSummaryEntity> getPatientSummary(String patientId);
}

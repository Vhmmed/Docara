import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/patient_summary_entity.dart';

sealed class MedicalRecordsState {
  const MedicalRecordsState();
}

class MedicalRecordsInitial extends MedicalRecordsState {
  const MedicalRecordsInitial();
}

class MedicalRecordsLoading extends MedicalRecordsState {
  const MedicalRecordsLoading();
}

class PatientInfoLoaded extends MedicalRecordsState {
  final PatientSummaryEntity summary;
  final List<MedicalRecordEntity> records;
  const PatientInfoLoaded(this.summary, this.records);
}

class MedicalRecordsError extends MedicalRecordsState {
  final String message;
  const MedicalRecordsError(this.message);
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/patient_summary_entity.dart';
import '../../domain/repositories/medical_record_repository.dart';
import 'medical_records_state.dart';

class MedicalRecordsCubit extends Cubit<MedicalRecordsState> {
  MedicalRecordsCubit(this._repository) : super(const MedicalRecordsInitial());

  final MedicalRecordRepository _repository;

  Future<void> loadPatientInfo(String patientId) async {
    emit(const MedicalRecordsLoading());
    try {
      final results = await Future.wait([
        _repository.getPatientSummary(patientId),
        _repository.getPatientRecords(patientId),
      ]);
      emit(PatientInfoLoaded(
        results[0] as PatientSummaryEntity,
        results[1] as List<MedicalRecordEntity>,
      ));
    } catch (e) {
      emit(MedicalRecordsError(e.toString()));
    }
  }
}

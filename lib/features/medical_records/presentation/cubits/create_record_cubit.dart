import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medical_record_entity.dart';
import '../../domain/repositories/medical_record_repository.dart';
import 'create_record_state.dart';

class CreateRecordCubit extends Cubit<CreateRecordState> {
  CreateRecordCubit(this._repository) : super(const CreateRecordInitial());

  final MedicalRecordRepository _repository;

  Future<void> submit({
    required String patientId,
    String? doctorId,
    required RecordType recordType,
    required String title,
    String? chiefComplaints,
    String? diagnosis,
    String? prescription,
    DateTime? followUpDate,
    String? additionalInstructions,
    String? fileUrl,
  }) async {
    emit(const CreateRecordSubmitting());
    try {
      await _repository.createRecord(
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
      );
      emit(const CreateRecordSuccess());
    } catch (e) {
      emit(CreateRecordError(e.toString()));
    }
  }

  void reset() => emit(const CreateRecordInitial());
}

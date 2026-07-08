import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordModel extends MedicalRecordEntity {
  const MedicalRecordModel({
    required super.id,
    required super.patientId,
    super.doctorId,
    super.recordType,
    required super.title,
    super.chiefComplaints,
    super.diagnosis,
    super.prescription,
    super.followUpDate,
    super.additionalInstructions,
    super.fileUrl,
    required super.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String?,
      recordType: _parseType(json['record_type'] as String?),
      title: json['title'] as String,
      chiefComplaints: json['chief_complaints'] as String?,
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      additionalInstructions: json['additional_instructions'] as String?,
      fileUrl: json['file_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      'record_type': recordType.name,
      'title': title,
      if (chiefComplaints != null) 'chief_complaints': chiefComplaints,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (prescription != null) 'prescription': prescription,
      if (followUpDate != null)
        'follow_up_date': followUpDate!.toIso8601String().split('T').first,
      if (additionalInstructions != null)
        'additional_instructions': additionalInstructions,
      if (fileUrl != null) 'file_url': fileUrl,
    };
  }

  static RecordType _parseType(String? type) => switch (type) {
    'labResult' || 'lab_result' => RecordType.labResult,
    'prescription' => RecordType.prescription,
    'imaging' => RecordType.imaging,
    'report' => RecordType.report,
    _ => RecordType.report,
  };
}

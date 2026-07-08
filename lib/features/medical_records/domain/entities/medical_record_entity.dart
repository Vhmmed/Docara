import 'package:equatable/equatable.dart';

enum RecordType { labResult, prescription, imaging, report }

class MedicalRecordEntity extends Equatable {
  final String id;
  final String patientId;
  final String? doctorId;
  final RecordType recordType;
  final String title;
  final String? chiefComplaints;
  final String? diagnosis;
  final String? prescription;
  final DateTime? followUpDate;
  final String? additionalInstructions;
  final String? fileUrl;
  final DateTime createdAt;

  const MedicalRecordEntity({
    required this.id,
    required this.patientId,
    this.doctorId,
    this.recordType = RecordType.report,
    required this.title,
    this.chiefComplaints,
    this.diagnosis,
    this.prescription,
    this.followUpDate,
    this.additionalInstructions,
    this.fileUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled, rejected }
enum AppointmentType { inPerson, video }

class AppointmentEntity extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final double fee;
  final bool isPaid;
  final DateTime createdAt;

  // Display fields (joined data)
  final String doctorName;
  final String specialty;
  final String location;
  final String? avatarUrl;
  final String patientName;
  final String? patientAvatarUrl;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.scheduledAt,
    required this.status,
    required this.type,
    this.notes,
    required this.fee,
    required this.isPaid,
    required this.createdAt,
    required this.doctorName,
    required this.specialty,
    required this.location,
    this.avatarUrl,
    required this.patientName,
    this.patientAvatarUrl,
  });

  String get dateFormatted =>
      DateFormat('EEE, MMM d').format(scheduledAt.toLocal());
  String get timeFormatted =>
      DateFormat('h:mm a').format(scheduledAt.toLocal());
  String get feeFormatted => '\$${fee.toStringAsFixed(0)}';

  static String statusLabel(AppointmentStatus s) => switch (s) {
    AppointmentStatus.pending => 'Pending',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.rejected => 'Rejected',
  };

  @override
  List<Object?> get props => [id, status];
}

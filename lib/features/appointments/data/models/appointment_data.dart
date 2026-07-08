import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_color.dart';

/// Typed representation of an appointment row joined with doctor/patient info.
class AppointmentData {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime scheduledAt;
  final String status;
  final String type;
  final String? notes;
  final double fee;
  final bool isPaid;
  final DateTime createdAt;

  // Joined fields
  final String doctorName;
  final String specialty;
  final String location;
  final String? avatarUrl;
  final String patientName;
  final String? patientAvatarUrl;

  const AppointmentData({
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
}

/// Status helpers reused by both patient and admin UIs.
Color appointmentStatusColor(String status) => switch (status) {
  'pending' => AppColors.warning,
  'confirmed' => AppColors.success,
  'completed' => AppColors.info,
  'cancelled' => AppColors.error,
  'rejected' => AppColors.error,
  _ => AppColors.textSecondary,
};

String appointmentStatusLabel(String status) => switch (status) {
  'pending' => 'Pending',
  'confirmed' => 'Confirmed',
  'completed' => 'Completed',
  'cancelled' => 'Cancelled',
  'rejected' => 'Rejected',
  _ => status,
};

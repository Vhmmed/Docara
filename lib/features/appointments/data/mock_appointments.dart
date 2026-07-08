// ---------------------------------------------------------------------------
// Mock data — UI only, no backend.
// Shared between appointments_page.dart and appointment_detail_sheet.dart.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../core/constants/app_color.dart';

enum MockStatus { pending, confirmed, completed, cancelled }

const mockStatusLabel = {
  MockStatus.pending: 'Pending',
  MockStatus.confirmed: 'Confirmed',
  MockStatus.completed: 'Completed',
  MockStatus.cancelled: 'Cancelled',
};

Color mockStatusColor(MockStatus s) => switch (s) {
  MockStatus.pending => AppColors.warning,
  MockStatus.confirmed => AppColors.success,
  MockStatus.completed => AppColors.info,
  MockStatus.cancelled => AppColors.error,
};

class MockAppointment {
  final String id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String location;
  final String fee;
  final MockStatus status;
  final String? notes;

  const MockAppointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.location,
    required this.fee,
    required this.status,
    this.notes,
  });
}

const mockUpcoming = [
  MockAppointment(
    id: 'A001',
    doctorName: 'Dr. Emily Chen',
    specialty: 'General Physician',
    date: 'Mon, Jul 15',
    time: '10:30 AM',
    location: 'Building B, Room 204, City Medical Center',
    fee: '\$45',
    status: MockStatus.confirmed,
    notes: 'Please bring your latest blood test results.',
  ),
  MockAppointment(
    id: 'A002',
    doctorName: 'Dr. James Carter',
    specialty: 'Cardiologist',
    date: 'Wed, Jul 17',
    time: '2:00 PM',
    location: 'Suite 310, Heart & Vascular Institute',
    fee: '\$80',
    status: MockStatus.pending,
  ),
  MockAppointment(
    id: 'A003',
    doctorName: 'Dr. Sarah Mitchell',
    specialty: 'Dermatologist',
    date: 'Fri, Jul 26',
    time: '9:00 AM',
    location: 'Clinic 5, Wellness Tower',
    fee: '\$60',
    status: MockStatus.confirmed,
    notes: 'Follow-up on previous treatment. Arrive 15 minutes early.',
  ),
];

const mockPast = [
  MockAppointment(
    id: 'A004',
    doctorName: 'Dr. Michael Torres',
    specialty: 'Orthopedist',
    date: 'Mon, Jun 24',
    time: '11:00 AM',
    location: 'Room 112, Bone & Joint Center',
    fee: '\$55',
    status: MockStatus.completed,
    notes: 'Patient reported improvement. Next visit in 3 months.',
  ),
  MockAppointment(
    id: 'A005',
    doctorName: 'Dr. Lisa Park',
    specialty: 'Neurologist',
    date: 'Wed, Jun 12',
    time: '3:30 PM',
    location: 'Suite 220, Neuroscience Pavilion',
    fee: '\$90',
    status: MockStatus.cancelled,
  ),
  MockAppointment(
    id: 'A006',
    doctorName: 'Dr. Robert Kim',
    specialty: 'General Physician',
    date: 'Sat, Jun 1',
    time: '8:30 AM',
    location: 'Building A, Room 105, City Medical Center',
    fee: '\$45',
    status: MockStatus.completed,
  ),
];

// ---------------------------------------------------------------------------
// Mock data — UI only, no backend.
// ---------------------------------------------------------------------------

import '../../appointments/data/mock_appointments.dart';

class MockTimeSlot {
  final String id;
  final String patientName;
  final String time;
  final String reason;
  final MockStatus status;
  final String? notes;

  const MockTimeSlot({
    required this.id,
    required this.patientName,
    required this.time,
    required this.reason,
    required this.status,
    this.notes,
  });
}

class MockDay {
  final DateTime date;
  final List<MockTimeSlot> slots;

  const MockDay({required this.date, required this.slots});
}

// Generate 7 days starting from today.
List<MockDay> buildMockDays() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    MockDay(
      date: today,
      slots: const [
        MockTimeSlot(
          id: 'S001', patientName: 'James Wilson', time: '9:00 AM',
          reason: 'Annual checkup', status: MockStatus.confirmed,
          notes: 'First visit. Bring previous medical records if available.',
        ),
        MockTimeSlot(
          id: 'S002', patientName: 'Maria Garcia', time: '10:30 AM',
          reason: 'Follow-up consultation', status: MockStatus.confirmed,
        ),
        MockTimeSlot(
          id: 'S003', patientName: 'Ahmed Hassan', time: '2:00 PM',
          reason: 'Blood work review', status: MockStatus.pending,
        ),
      ],
    ),
    MockDay(
      date: today.add(const Duration(days: 1)),
      slots: const [
        MockTimeSlot(
          id: 'S004', patientName: 'Sophie Turner', time: '11:00 AM',
          reason: 'Vaccination', status: MockStatus.confirmed,
          notes: 'Patient has mild allergy to penicillin — note in file.',
        ),
        MockTimeSlot(
          id: 'S005', patientName: 'David Kim', time: '3:30 PM',
          reason: 'ECG & stress test results', status: MockStatus.completed,
        ),
      ],
    ),
    MockDay(
      date: today.add(const Duration(days: 2)),
      slots: const [
        MockTimeSlot(
          id: 'S006', patientName: 'Olivia Brown', time: '8:30 AM',
          reason: 'Prescription renewal', status: MockStatus.confirmed,
        ),
      ],
    ),
    MockDay(
      date: today.add(const Duration(days: 3)),
      slots: const [],
    ),
    MockDay(
      date: today.add(const Duration(days: 4)),
      slots: const [
        MockTimeSlot(
          id: 'S007', patientName: 'Liam Chen', time: '1:00 PM',
          reason: 'Allergy test review', status: MockStatus.pending,
        ),
        MockTimeSlot(
          id: 'S008', patientName: 'Emma Rodriguez', time: '4:00 PM',
          reason: 'Physical therapy assessment', status: MockStatus.cancelled,
        ),
      ],
    ),
    MockDay(
      date: today.add(const Duration(days: 5)),
      slots: const [
        MockTimeSlot(
          id: 'S009', patientName: 'Noah Patel', time: '10:00 AM',
          reason: 'Follow-up consultation', status: MockStatus.confirmed,
          notes: 'Post-surgery checkup. Expect 30 min appointment.',
        ),
      ],
    ),
    MockDay(
      date: today.add(const Duration(days: 6)),
      slots: const [],
    ),
  ];
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:medical_booking_app/core/errors/failures.dart';
import 'package:medical_booking_app/features/appointments/domain/entities/appointment_entity.dart';
import 'package:medical_booking_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:medical_booking_app/features/appointments/presentation/cubits/appointment_cubit.dart';

// ---------------------------------------------------------------------------
// Fake repository — returns controlled data, no network, no mocking framework.
// ---------------------------------------------------------------------------
class FakeAppointmentRepository implements AppointmentRepository {
  /// Appointments that will be returned by [getMyAppointments].
  List<AppointmentEntity> appointments = [];

  /// If non-null, every repo call returns [Left(failure)].
  Failure? failWith;

  /// Tracks the last booked appointment params.
  String? bookedDoctorId;
  DateTime? bookedScheduledAt;
  String? bookedType;
  String? bookedNotes;

  /// Tracks last cancelled id.
  String? cancelledId;

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getMyAppointments() async {
    if (failWith != null) return Left(failWith!);
    return Right(appointments);
  }

  @override
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required String type,
    String? notes,
  }) async {
    if (failWith != null) return Left(failWith!);
    bookedDoctorId = doctorId;
    bookedScheduledAt = scheduledAt;
    bookedType = type;
    bookedNotes = notes;
    final entity = AppointmentEntity(
      id: 'new-id',
      patientId: 'patient-id',
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      status: AppointmentStatus.pending,
      type: type == 'video' ? AppointmentType.video : AppointmentType.inPerson,
      notes: notes,
      fee: 0,
      isPaid: false,
      createdAt: DateTime.now(),
      doctorName: 'Dr. Test',
      specialty: 'General',
      location: 'Clinic',
      patientName: 'Patient Test',
    );
    appointments = [entity, ...appointments];
    return Right(entity);
  }

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(
      String id) async {
    if (failWith != null) return Left(failWith!);
    cancelledId = id;
    appointments = appointments
        .map((e) =>
            e.id == id
                ? AppointmentEntity(
                    id: e.id,
                    patientId: e.patientId,
                    doctorId: e.doctorId,
                    scheduledAt: e.scheduledAt,
                    status: AppointmentStatus.cancelled,
                    type: e.type,
                    notes: e.notes,
                    fee: e.fee,
                    isPaid: e.isPaid,
                    createdAt: e.createdAt,
                    doctorName: e.doctorName,
                    specialty: e.specialty,
                    location: e.location,
                    avatarUrl: e.avatarUrl,
                    patientName: e.patientName,
                    patientAvatarUrl: e.patientAvatarUrl,
                  )
                : e)
        .toList();
    return Right(appointments.firstWhere((e) => e.id == id));
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String id,
    required DateTime newTime,
  }) =>
      Future.value(Right(appointments.first));

  @override
  Future<Either<Failure, AppointmentEntity>> updateStatus({
    required String id,
    required AppointmentStatus status,
  }) =>
      Future.value(Right(appointments.first));

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getApprovedDoctors() async {
    if (failWith != null) return Left(failWith!);
    return Right([]);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
AppointmentEntity sampleAppointment({
  String id = 'a1',
  AppointmentStatus status = AppointmentStatus.pending,
  DateTime? scheduledAt,
}) {
  return AppointmentEntity(
    id: id,
    patientId: 'p1',
    doctorId: 'd1',
    scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
    status: status,
    type: AppointmentType.inPerson,
    fee: 100,
    isPaid: false,
    createdAt: DateTime.now(),
    doctorName: 'Dr. Smith',
    specialty: 'Cardiology',
    location: 'Room 101',
    patientName: 'John Patient',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late FakeAppointmentRepository fakeRepo;
  late AppointmentCubit cubit;

  setUp(() {
    fakeRepo = FakeAppointmentRepository();
    cubit = AppointmentCubit(
      repository: fakeRepo,
      currentUserId: 'test-user',
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('AppointmentCubit', () {
    // =====================================================================
    // Initial state
    // =====================================================================
    test('emits AppointmentState with correct initial values', () {
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, null);
      expect(cubit.state.upcoming, isEmpty);
      expect(cubit.state.past, isEmpty);
      expect(cubit.state.isSubmitting, false);
      expect(cubit.state.isLoadingDoctors, false);
      expect(cubit.state.doctors, isEmpty);
      expect(cubit.state.doctorsError, null);
    });

    // =====================================================================
    // Flow 1: Load appointments (view list)
    // =====================================================================
    group('loadAppointments', () {
      test('transitions: initial → loading → loaded (upcoming/past split)', () async {
        final futureDate1 = DateTime.now().add(const Duration(days: 3));
        final futureDate2 = DateTime.now().add(const Duration(days: 5));
        final pastDate = DateTime.now().subtract(const Duration(days: 5));

        fakeRepo.appointments = [
          sampleAppointment(id: 'a1', status: AppointmentStatus.confirmed, scheduledAt: futureDate2),
          sampleAppointment(id: 'a2', status: AppointmentStatus.completed, scheduledAt: pastDate),
          sampleAppointment(id: 'a3', status: AppointmentStatus.pending, scheduledAt: futureDate1),
        ];

        final emitted = <AppointmentState>[];
        cubit.stream.listen(emitted.add);

        cubit.loadAppointments();
        await Future.delayed(Duration.zero); // let the async settle

        // — state 2: loading complete
        final s = cubit.state;
        expect(s.isLoading, false);
        expect(s.error, null);

        // upcoming: pending/confirmed in the future, sorted by date ascending
        expect(s.upcoming.length, 2);
        expect(s.upcoming[0].id, 'a3'); // earlier date
        expect(s.upcoming[1].id, 'a1'); // later date

        // past: everything else
        expect(s.past.length, 1);
        expect(s.past[0].id, 'a2');

        // Verify full emitted sequence
        expect(emitted.length, 2);
        expect(emitted[0].isLoading, true);  // loading emitted
        expect(emitted[1].isLoading, false); // loaded emitted
      });

      test('handles failure — transitions: loading → error', () async {
        fakeRepo.failWith = ServerFailure('Network error');

        cubit.loadAppointments();
        await Future.delayed(Duration.zero);

        final s = cubit.state;
        expect(s.isLoading, false);
        expect(s.error, contains('Network error'));
        expect(s.upcoming, isEmpty);
        expect(s.past, isEmpty);
      });
    });

    // =====================================================================
    // Flow 2: Book appointment
    // =====================================================================
    group('bookAppointment', () {
      test('transitions: submitting → done, saves repo call, refreshes list',
          () async {
        final futureDate = DateTime.now().add(const Duration(days: 7));

        // Start with one existing appointment
        fakeRepo.appointments = [
          sampleAppointment(id: 'existing-1'),
        ];

        // Pre-load the list
        cubit.loadAppointments();
        await Future.delayed(Duration.zero);
        expect(cubit.state.upcoming.length, 1);

        // Book a new one
        await cubit.bookAppointment(
          doctorId: 'd2',
          scheduledAt: futureDate,
          type: 'video',
          notes: 'Test booking',
        );

        // Verify repo was called correctly
        expect(fakeRepo.bookedDoctorId, 'd2');
        expect(fakeRepo.bookedType, 'video');
        expect(fakeRepo.bookedNotes, 'Test booking');

        // After booking, the cubit calls loadAppointments internally.
        // The newly added appointment should appear.
        final s = cubit.state;
        expect(s.isSubmitting, false);
        expect(s.error, null);
        expect(s.upcoming.length, 2); // existing + new
      });

      test('handles failure — transitions: submitting → error', () async {
        fakeRepo.failWith = ServerFailure('Booking failed');

        cubit.loadAppointments(); // pre-load
        await Future.delayed(Duration.zero);

        await cubit.bookAppointment(
          doctorId: 'd2',
          scheduledAt: DateTime.now().add(const Duration(days: 7)),
          type: 'in_person',
        );

        final s = cubit.state;
        expect(s.isSubmitting, false);
        expect(s.error, contains('Booking failed'));
      });
    });

    // =====================================================================
    // Flow 3: Cancel appointment
    // =====================================================================
    group('cancelAppointment', () {
      test('transitions: submitting → done, status flips to cancelled', () async {
        fakeRepo.appointments = [
          sampleAppointment(id: 'to-cancel'),
        ];

        cubit.loadAppointments();
        await Future.delayed(Duration.zero);
        expect(cubit.state.upcoming.length, 1);

        // Cancel it
        await cubit.cancelAppointment('to-cancel');

        expect(fakeRepo.cancelledId, 'to-cancel');

        // After cancel triggers reload, the appointment moves to past
        // because its status is now cancelled.
        final s = cubit.state;
        expect(s.isSubmitting, false);
        expect(s.error, null);
        expect(s.upcoming.where((e) => e.id == 'to-cancel'), isEmpty);
        expect(s.past.any((e) => e.id == 'to-cancel'), true);
        expect(s.past.firstWhere((e) => e.id == 'to-cancel').status,
            AppointmentStatus.cancelled);
      });

      test('handles failure — transitions: submitting → error', () async {
        fakeRepo.appointments = [sampleAppointment(id: 'to-cancel')];
        cubit.loadAppointments();
        await Future.delayed(Duration.zero);

        fakeRepo.failWith = ServerFailure('Cancel failed');

        await cubit.cancelAppointment('to-cancel');

        final s = cubit.state;
        expect(s.isSubmitting, false);
        expect(s.error, contains('Cancel failed'));
      });
    });

    // =====================================================================
    // Flow 4: Load doctors (for booking sheet)
    // =====================================================================
    group('loadDoctors', () {
      test('transitions: loading → loaded with doctor list', () async {
        // Fake repo returns an empty list by default, which is fine
        final emitted = <AppointmentState>[];
        cubit.stream.listen(emitted.add);

        cubit.loadDoctors();
        await Future.delayed(Duration.zero);

        final s = cubit.state;
        expect(s.isLoadingDoctors, false);
        expect(s.doctorsError, null);
        expect(s.doctors, isA<List<Map<String, dynamic>>>());

        expect(emitted.length, 2);
        expect(emitted[0].isLoadingDoctors, true);
        expect(emitted[1].isLoadingDoctors, false);
      });

      test('handles failure', () async {
        fakeRepo.failWith = ServerFailure('No doctors');

        cubit.loadDoctors();
        await Future.delayed(Duration.zero);

        final s = cubit.state;
        expect(s.isLoadingDoctors, false);
        expect(s.doctorsError, contains('No doctors'));
      });
    });

    // =====================================================================
    // Edge case: rapid successive calls
    // =====================================================================
    test('rapid loadAppointments calls do not collide', () async {
      fakeRepo.appointments = [
        sampleAppointment(id: 'a1'),
      ];

      // Fire two loadAppointments quickly
      cubit.loadAppointments();
      cubit.loadAppointments();
      await Future.delayed(Duration.zero);

      final s = cubit.state;
      expect(s.isLoading, false);
      expect(s.upcoming.length, 1);
    });
  });
}

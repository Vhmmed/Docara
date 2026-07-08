import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../appointment_service.dart';
import '../models/appointment_data.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  @override
  Future<Either<Failure, List<AppointmentEntity>>> getMyAppointments() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await AppointmentService.getPatientAppointments(userId);
      final entities = data.map(_toEntity).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required String type,
    String? notes,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fee = await _fetchDoctorFee(doctorId);
      await AppointmentService.bookAppointment(
        patientId: userId,
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        type: type == 'video' ? 'video' : 'in_person',
        notes: notes,
        fee: fee,
      );
      // Return a minimal entity (full list will be refetched)
      return Right(AppointmentEntity(
        id: '',
        patientId: userId,
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        status: AppointmentStatus.pending,
        type: type == 'video' ? AppointmentType.video : AppointmentType.inPerson,
        notes: notes,
        fee: fee,
        isPaid: false,
        createdAt: DateTime.now(),
        doctorName: '',
        specialty: '',
        location: '',
        patientName: '',
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(
      String id) async {
    try {
      await AppointmentService.cancelAppointment(id);
      return Right(AppointmentEntity(
        id: id,
        patientId: '',
        doctorId: '',
        scheduledAt: DateTime.now(),
        status: AppointmentStatus.cancelled,
        type: AppointmentType.inPerson,
        fee: 0,
        isPaid: false,
        createdAt: DateTime.now(),
        doctorName: '',
        specialty: '',
        location: '',
        patientName: '',
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String id,
    required DateTime newTime,
  }) async {
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'scheduled_at': newTime.toUtc().toIso8601String()})
          .eq('id', id);
      return Right(AppointmentEntity(
        id: id,
        patientId: '',
        doctorId: '',
        scheduledAt: newTime,
        status: AppointmentStatus.pending,
        type: AppointmentType.inPerson,
        fee: 0,
        isPaid: false,
        createdAt: DateTime.now(),
        doctorName: '',
        specialty: '',
        location: '',
        patientName: '',
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> updateStatus({
    required String id,
    required AppointmentStatus status,
  }) async {
    try {
      final statusStr = switch (status) {
        AppointmentStatus.pending => 'pending',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.rejected => 'rejected',
      };
      await AppointmentService.updateStatus(id, statusStr);
      return Right(AppointmentEntity(
        id: id,
        patientId: '',
        doctorId: '',
        scheduledAt: DateTime.now(),
        status: status,
        type: AppointmentType.inPerson,
        fee: 0,
        isPaid: false,
        createdAt: DateTime.now(),
        doctorName: '',
        specialty: '',
        location: '',
        patientName: '',
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getApprovedDoctors() async {
    try {
      final doctors = await AppointmentService.getApprovedDoctors();
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  static AppointmentEntity _toEntity(AppointmentData d) {
    return AppointmentEntity(
      id: d.id,
      patientId: d.patientId,
      doctorId: d.doctorId,
      scheduledAt: d.scheduledAt,
      status: _parseStatus(d.status),
      type: _parseType(d.type),
      notes: d.notes,
      fee: d.fee,
      isPaid: d.isPaid,
      createdAt: d.createdAt,
      doctorName: d.doctorName,
      specialty: d.specialty,
      location: d.location,
      avatarUrl: d.avatarUrl,
      patientName: d.patientName,
      patientAvatarUrl: d.patientAvatarUrl,
    );
  }

  static AppointmentStatus _parseStatus(String s) => switch (s) {
    'pending' => AppointmentStatus.pending,
    'confirmed' => AppointmentStatus.confirmed,
    'completed' => AppointmentStatus.completed,
    'cancelled' => AppointmentStatus.cancelled,
    'rejected' => AppointmentStatus.rejected,
    _ => AppointmentStatus.pending,
  };

  static AppointmentType _parseType(String s) => switch (s) {
    'in_person' => AppointmentType.inPerson,
    'video' => AppointmentType.video,
    _ => AppointmentType.inPerson,
  };

  Future<double> _fetchDoctorFee(String doctorId) async {
    final doctor = await Supabase.instance.client
        .from('doctors')
        .select('consultation_fee')
        .eq('id', doctorId)
        .single();
    return (doctor['consultation_fee'] as num?)?.toDouble() ?? 0;
  }
}

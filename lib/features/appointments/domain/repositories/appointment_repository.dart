import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, List<AppointmentEntity>>> getMyAppointments();
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required String type,
    String? notes,
  });
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(String id);
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String id,
    required DateTime newTime,
  });
  Future<Either<Failure, AppointmentEntity>> updateStatus({
    required String id,
    required AppointmentStatus status,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> getApprovedDoctors();
}

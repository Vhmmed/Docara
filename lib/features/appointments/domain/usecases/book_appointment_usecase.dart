import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class BookAppointmentUseCase extends UseCase<AppointmentEntity, BookParams> {
  final AppointmentRepository repository;
  BookAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(BookParams params) {
    return repository.bookAppointment(
      doctorId: params.doctorId,
      scheduledAt: params.scheduledAt,
      type: params.type,
      notes: params.notes,
    );
  }
}

class BookParams extends Equatable {
  final String doctorId;
  final DateTime scheduledAt;
  final String type;
  final String? notes;
  const BookParams({
    required this.doctorId, required this.scheduledAt,
    required this.type, this.notes,
  });
  @override
  List<Object?> get props => [doctorId, scheduledAt];
}

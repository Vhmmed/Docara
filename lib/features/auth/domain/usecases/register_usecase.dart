import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
      role: params.role,
      dateOfBirth: params.dateOfBirth,
      specialtyId: params.specialtyId,
    );
  }
}

class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String phone;
  final UserRole role;
  final DateTime? dateOfBirth;
  final String? specialtyId;
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    this.dateOfBirth,
    this.specialtyId,
  });

  @override
  List<Object> get props => [email, role];
}

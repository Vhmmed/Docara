import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Left(AuthFailure('Sign-in failed'));
      }
      return Right(_mapUserToEntity(user));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        const AuthFailure('Unable to sign in. Check your connection.'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    DateTime? dateOfBirth,
    String? specialtyId,
  }) async {
    try {
      final isDoctor = role == UserRole.doctor;
      final response = await _remote.signUp(
        email: email,
        password: password,
        data: {
          'role': role.name,
          'full_name': name,
          'phone': phone,
          if (dateOfBirth != null)
            'date_of_birth':
                dateOfBirth.toIso8601String().split('T').first,
          if (isDoctor && specialtyId != null)
            'specialty_id': specialtyId,
          'status': isDoctor ? 'pending' : 'approved',
        },
      );
      final user = response.user;
      if (user == null) {
        return const Left(AuthFailure(
          'Sign up succeeded but could not retrieve user ID. '
          'Please try signing in with your credentials.',
        ));
      }

      await _remote.upsertProfile({
        'id': user.id,
        'role': role.name,
        'full_name': name,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });

      return Right(_mapUserToEntity(user));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        const AuthFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(String otp) async {
    return const Left(ServerFailure('OTP verification not implemented'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = _remote.currentUser;
      if (user == null) return const Right(null);
      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _remote.resetPasswordForEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        const AuthFailure('Unable to send reset email. Check your connection.'),
      );
    }
  }

  UserEntity _mapUserToEntity(User user) {
    final metadata = user.userMetadata ?? {};
    return UserEntity(
      id: user.id,
      name: (metadata['full_name'] as String?) ??
          user.email?.split('@').first ??
          'User',
      email: user.email ?? '',
      phone: metadata['phone'] as String?,
      profileImage: metadata['avatar_url'] as String?,
      role: _parseRole(metadata['role'] as String?),
      isVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }
}

import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepositoryImpl _repository;

  ProfileCubit(this._repository) : super(const ProfileInitial());

  Future<void> fetchProfile() async {
    emit(const ProfileLoading());
    try {
      final profile = await _repository.fetchProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      developer.log('ProfileCubit.fetchProfile error: $e', name: 'ProfileCubit');
      emit(const ProfileError('Failed to load profile'));
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUploading(current.profile));
    try {
      final url = await _repository.uploadAvatar(filePath);
      final updated = current.profile.copyWith(avatarUrl: url);
      emit(ProfileLoaded(updated));
    } catch (e) {
      developer.log('ProfileCubit.uploadAvatar error: $e', name: 'ProfileCubit');
      emit(current);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
  }) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileSubmitting(current.profile));
    try {
      await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodType: bloodType,
        allergies: allergies,
        medicalConditions: medicalConditions,
      );
      final updated = current.profile.copyWith(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodType: bloodType,
        allergies: allergies,
        medicalConditions: medicalConditions,
      );
      emit(ProfileLoaded(updated));
    } catch (e) {
      developer.log('ProfileCubit.updateProfile error: $e', name: 'ProfileCubit');
      emit(current);
      rethrow;
    }
  }
}

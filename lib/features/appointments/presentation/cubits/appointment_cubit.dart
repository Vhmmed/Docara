import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class AppointmentState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<AppointmentEntity> upcoming;
  final List<AppointmentEntity> past;
  final bool isSubmitting;

  // Booking sheet state
  final bool isLoadingDoctors;
  final List<Map<String, dynamic>> doctors;
  final String? doctorsError;

  const AppointmentState({
    this.isLoading = false,
    this.error,
    this.upcoming = const [],
    this.past = const [],
    this.isSubmitting = false,
    this.isLoadingDoctors = false,
    this.doctors = const [],
    this.doctorsError,
  });

  AppointmentState copyWith({
    bool? isLoading,
    String? error,
    List<AppointmentEntity>? upcoming,
    List<AppointmentEntity>? past,
    bool? isSubmitting,
    bool? isLoadingDoctors,
    List<Map<String, dynamic>>? doctors,
    String? doctorsError,
    bool clearError = false,
    bool clearDoctorsError = false,
  }) =>
      AppointmentState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        upcoming: upcoming ?? this.upcoming,
        past: past ?? this.past,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isLoadingDoctors: isLoadingDoctors ?? this.isLoadingDoctors,
        doctors: doctors ?? this.doctors,
        doctorsError: clearDoctorsError ? null : (doctorsError ?? this.doctorsError),
      );

  @override
  List<Object?> get props =>
      [isLoading, error, upcoming, past, isSubmitting, isLoadingDoctors, doctors, doctorsError];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------
class AppointmentCubit extends Cubit<AppointmentState> {
  final AppointmentRepository _repository;
  final String currentUserId;

  AppointmentCubit({
    required AppointmentRepository repository,
    String? currentUserId,
  }) : _repository = repository,
      currentUserId = currentUserId ?? Supabase.instance.client.auth.currentUser!.id,
      super(const AppointmentState());

  // ---- Appointments -------------------------------------------------------

  Future<void> loadAppointments() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _repository.getMyAppointments();
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
        (entities) {
          final now = DateTime.now();
          final upcoming = <AppointmentEntity>[];
          final past = <AppointmentEntity>[];
          for (final e in entities) {
            if ((e.status == AppointmentStatus.pending ||
                    e.status == AppointmentStatus.confirmed) &&
                e.scheduledAt.isAfter(now)) {
              upcoming.add(e);
            } else {
              past.add(e);
            }
          }
          upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          emit(state.copyWith(
            isLoading: false,
            upcoming: upcoming,
            past: past,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // ---- Booking -----------------------------------------------------------

  Future<void> loadDoctors() async {
    emit(state.copyWith(isLoadingDoctors: true, clearDoctorsError: true));
    try {
      final result = await _repository.getApprovedDoctors();
      result.fold(
        (failure) => emit(state.copyWith(isLoadingDoctors: false, doctorsError: failure.message)),
        (doctors) => emit(state.copyWith(isLoadingDoctors: false, doctors: doctors)),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingDoctors: false, doctorsError: e.toString()));
    }
  }

  Future<void> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required String type,
    String? notes,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final result = await _repository.bookAppointment(
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        type: type,
        notes: notes,
      );
      result.fold(
        (failure) => emit(state.copyWith(isSubmitting: false, error: failure.message)),
        (_) => emit(state.copyWith(isSubmitting: false)),
      );
      if (result.isRight()) {
        await loadAppointments();
      }
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  // ---- Cancel -----------------------------------------------------------

  Future<void> cancelAppointment(String id) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final result = await _repository.cancelAppointment(id);
      result.fold(
        (failure) => emit(state.copyWith(isSubmitting: false, error: failure.message)),
        (_) => emit(state.copyWith(isSubmitting: false)),
      );
      if (result.isRight()) {
        await loadAppointments();
      }
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}

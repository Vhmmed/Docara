import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/doctor_dashboard_repository.dart';
import 'doctor_dashboard_state.dart';

class DoctorDashboardCubit extends Cubit<DoctorDashboardState> {
  DoctorDashboardCubit(this._repository) : super(const DoctorDashboardInitial());

  final DoctorDashboardRepository _repository;

  Future<void> loadDashboard() async {
    emit(const DoctorDashboardLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const DoctorDashboardError('Not authenticated'));
        return;
      }
      final data = await _repository.getDashboard(userId);
      emit(DoctorDashboardLoaded(data));
    } catch (e) {
      emit(DoctorDashboardError(e.toString()));
    }
  }
}

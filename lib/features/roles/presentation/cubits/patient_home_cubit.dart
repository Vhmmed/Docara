import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/patient_home_repository.dart';
import 'patient_home_state.dart';

class PatientHomeCubit extends Cubit<PatientHomeState> {
  PatientHomeCubit(this._repository) : super(const PatientHomeInitial());

  final PatientHomeRepository _repository;

  Future<void> loadHome() async {
    emit(const PatientHomeLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const PatientHomeError('Not authenticated'));
        return;
      }
      final data = await _repository.getHomeData(userId);
      emit(PatientHomeLoaded(data));
    } catch (e) {
      emit(PatientHomeError(e.toString()));
    }
  }
}

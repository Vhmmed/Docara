import '../../domain/entities/patient_home_data.dart';

sealed class PatientHomeState {
  const PatientHomeState();
}

class PatientHomeInitial extends PatientHomeState {
  const PatientHomeInitial();
}

class PatientHomeLoading extends PatientHomeState {
  const PatientHomeLoading();
}

class PatientHomeLoaded extends PatientHomeState {
  final PatientHomeData data;
  const PatientHomeLoaded(this.data);
}

class PatientHomeError extends PatientHomeState {
  final String message;
  const PatientHomeError(this.message);
}

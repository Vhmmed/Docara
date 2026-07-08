import '../../domain/entities/doctor_dashboard_data.dart';

sealed class DoctorDashboardState {
  const DoctorDashboardState();
}

class DoctorDashboardInitial extends DoctorDashboardState {
  const DoctorDashboardInitial();
}

class DoctorDashboardLoading extends DoctorDashboardState {
  const DoctorDashboardLoading();
}

class DoctorDashboardLoaded extends DoctorDashboardState {
  final DoctorDashboardData data;
  const DoctorDashboardLoaded(this.data);
}

class DoctorDashboardError extends DoctorDashboardState {
  final String message;
  const DoctorDashboardError(this.message);
}

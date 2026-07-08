import '../entities/doctor_dashboard_data.dart';

abstract class DoctorDashboardRepository {
  Future<DoctorDashboardData> getDashboard(String doctorId);
}

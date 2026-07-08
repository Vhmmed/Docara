import '../entities/patient_home_data.dart';

abstract class PatientHomeRepository {
  Future<String?> getUserName(String userId);
  Future<PatientHomeData> getHomeData(String patientId);
}

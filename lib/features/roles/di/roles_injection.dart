import 'package:get_it/get_it.dart';

import '../data/repositories/doctor_dashboard_repository_impl.dart';
import '../data/repositories/patient_home_repository_impl.dart';
import '../domain/repositories/doctor_dashboard_repository.dart';
import '../domain/repositories/patient_home_repository.dart';
import '../presentation/cubits/doctor_dashboard_cubit.dart';
import '../presentation/cubits/patient_home_cubit.dart';

void initRoles(GetIt sl) {
  sl.registerLazySingleton<DoctorDashboardRepository>(
    () => DoctorDashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PatientHomeRepository>(
    () => PatientHomeRepositoryImpl(sl()),
  );
  sl.registerFactory<DoctorDashboardCubit>(
    () => DoctorDashboardCubit(sl()),
  );
  sl.registerFactory<PatientHomeCubit>(
    () => PatientHomeCubit(sl()),
  );
}

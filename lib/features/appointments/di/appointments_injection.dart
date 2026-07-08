import 'package:get_it/get_it.dart';
import '../data/repositories/appointment_repository_impl.dart';
import '../domain/repositories/appointment_repository.dart';
import '../presentation/cubits/appointment_cubit.dart';

void initAppointments(GetIt sl) {
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(),
  );
  sl.registerFactory(
    () => AppointmentCubit(repository: sl()),
  );
}

import 'package:get_it/get_it.dart';

import '../data/repositories/medical_record_repository_impl.dart';
import '../domain/repositories/medical_record_repository.dart';
import '../presentation/cubits/create_record_cubit.dart';
import '../presentation/cubits/medical_records_cubit.dart';

void initmedical_records(GetIt sl) {
  sl.registerLazySingleton<MedicalRecordRepository>(
    () => MedicalRecordRepositoryImpl(sl()),
  );
  sl.registerFactory(() => MedicalRecordsCubit(sl()));
  sl.registerFactory(() => CreateRecordCubit(sl()));
}

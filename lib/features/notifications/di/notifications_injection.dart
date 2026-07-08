import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';

void initnotifications(GetIt sl) {
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<SupabaseClient>()),
  );
}

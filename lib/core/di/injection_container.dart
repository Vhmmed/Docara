import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/appointments/di/appointments_injection.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/chat/di/chat_injection.dart';
import '../../features/medical_records/di/medical_records_injection.dart';
import '../../features/notifications/di/notifications_injection.dart';
import '../../features/payments/di/payments_injection.dart';
import '../../features/reviews/di/reviews_injection.dart';
import '../../features/roles/di/roles_injection.dart';
import '../services/presence_service.dart';
import '../services/unread_count_cubit.dart';
import '../../features/notifications/presentation/cubits/notification_unread_count_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  sl.registerLazySingleton<UnreadCountCubit>(() => UnreadCountCubit());
  sl.registerLazySingleton<NotificationUnreadCountCubit>(
    () => NotificationUnreadCountCubit(),
  );
  sl.registerLazySingleton<PresenceService>(
    () => PresenceService(sl<SupabaseClient>()),
  );

  initAuth(sl);
  initAppointments(sl);
  initRoles(sl);
  initchat(sl);
  initmedical_records(sl);
  initnotifications(sl);
  initpayments(sl);
  initreviews(sl);
}

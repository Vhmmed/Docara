import 'package:get_it/get_it.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/chat_repository.dart';

void initchat(GetIt sl) {
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
}

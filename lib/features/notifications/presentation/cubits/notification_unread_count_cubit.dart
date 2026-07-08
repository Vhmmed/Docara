import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationUnreadCountCubit extends Cubit<int> {
  RealtimeChannel? _channel;
  String? _userId;
  StreamSubscription<AuthState>? _authSubscription;

  NotificationUnreadCountCubit() : super(0);

  void init(String userId) {
    if (_userId == userId && _channel != null) return;
    _userId = userId;
    _subscribe();
    _listenAuthChanges();
  }

  void setCount(int count) => emit(count);

  void increment() => emit(state + 1);

  void decrement() {
    if (state > 0) emit(state - 1);
  }

  void _subscribe() {
    _channel?.unsubscribe();
    final uid = _userId;
    if (uid == null) return;

    _channel = Supabase.instance.client.channel('notifications:unread:$uid');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        column: 'user_id',
        type: PostgresChangeFilterType.eq,
        value: uid,
      ),
      callback: (_) => increment(),
    );
    _channel!.subscribe();
  }

  void _listenAuthChanges() {
    _authSubscription ??= Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        final newId = event.session?.user.id;
        if (newId != _userId) {
          _channel?.unsubscribe();
          _channel = null;
          _userId = null;
          emit(0);
          if (newId != null) init(newId);
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _channel?.unsubscribe();
    return super.close();
  }
}

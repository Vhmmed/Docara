import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_unread_count_cubit.dart';

part 'notification_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _repository;
  final String userId;
  final NotificationUnreadCountCubit _unreadCountCubit;
  RealtimeChannel? _channel;

  NotificationsCubit({
    required NotificationRepository repository,
    required this.userId,
    required NotificationUnreadCountCubit unreadCountCubit,
  })  : _repository = repository,
        _unreadCountCubit = unreadCountCubit,
        super(const NotificationsState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final notifications = await _repository.getNotifications(userId);
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
      ));
      _updateUnreadCount(notifications);
      _subscribe();
    } catch (e) {
      developer.log('loadNotifications error: $e', name: 'NotificationsCubit');
      emit(state.copyWith(
        status: NotificationsStatus.error,
        error: 'Failed to load notifications',
      ));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final updated = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      emit(state.copyWith(notifications: updated));
      _updateUnreadCount(updated);
    } catch (e) {
      developer.log('markAsRead error: $e', name: 'NotificationsCubit');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead(userId);
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(state.copyWith(notifications: updated));
      _updateUnreadCount(updated);
    } catch (e) {
      developer.log('markAllAsRead error: $e', name: 'NotificationsCubit');
    }
  }

  void _subscribe() {
    _channel?.unsubscribe();
    final current = state;
    if (current.status != NotificationsStatus.loaded) return;

    final channel = Supabase.instance.client.channel('notifications:$userId');
    _channel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        column: 'user_id',
        type: PostgresChangeFilterType.eq,
        value: userId,
      ),
      callback: (payload) {
        final record = Map<String, dynamic>.from(payload.newRecord);
        final notification = _mapRecord(record);
        if (notification == null) return;

        final updated = [notification, ...current.notifications];
        emit(state.copyWith(notifications: updated));
        _updateUnreadCount(updated);
      },
    );

    channel.subscribe();
  }

  NotificationEntity? _mapRecord(Map<String, dynamic> record) {
    try {
      return NotificationEntity(
        id: record['id'] as String,
        type: record['type'] as String,
        title: record['title'] as String,
        body: record['body'] as String,
        data: Map<String, dynamic>.from(record['data'] as Map? ?? {}),
        isRead: record['is_read'] as bool? ?? false,
        createdAt:
            parseSupabaseTimestamp(record['created_at'] as String?) ??
                DateTime.now(),
      );
    } catch (e) {
      developer.log('mapRecord error: $e', name: 'NotificationsCubit');
      return null;
    }
  }

  void _updateUnreadCount(List<NotificationEntity> notifications) {
    final count = notifications.where((n) => !n.isRead).length;
    _unreadCountCubit.setCount(count);
  }

  @override
  Future<void> close() async {
    await _channel?.unsubscribe();
    return super.close();
  }
}

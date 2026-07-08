import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _client;

  NotificationRepositoryImpl(this._client);

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    final result = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final rows = (result as List).cast<Map<String, dynamic>>();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final result = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (result as List).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  NotificationEntity _mapRow(Map<String, dynamic> row) {
    return NotificationEntity(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      data: Map<String, dynamic>.from(row['data'] as Map? ?? {}),
      isRead: row['is_read'] as bool? ?? false,
      createdAt: parseSupabaseTimestamp(row['created_at'] as String?) ?? DateTime.now(),
    );
  }
}

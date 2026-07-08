import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _client;

  ChatRepositoryImpl(this._client);

  @override
  Future<Map<String, dynamic>> getOrCreateConversation({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final existing = await _client
          .from('conversations')
          .select()
          .eq('patient_id', patientId)
          .eq('doctor_id', doctorId)
          .maybeSingle();

      if (existing != null) {
        return Map<String, dynamic>.from(existing);
      }

      final inserted = await _client.from('conversations').insert({
        'patient_id': patientId,
        'doctor_id': doctorId,
      }).select().single();

      developer.log(
        'Created conversation patient=$patientId doctor=$doctorId',
        name: 'ChatRepositoryImpl.getOrCreateConversation',
      );

      return Map<String, dynamic>.from(inserted);
    } catch (e) {
      developer.log(
        'getOrCreateConversation error: $e',
        name: 'ChatRepositoryImpl',
      );
      rethrow;
    }
  }

  @override
  Future<List<ConversationData>> getUserConversations({
    required String userId,
    required String role,
  }) async {
    try {
      List<Map<String, dynamic>> rows;

      if (role == 'patient') {
        final result = await _client
            .from('conversations')
            .select()
            .eq('patient_id', userId)
            .order('created_at', ascending: false);
        rows = (result as List).cast<Map<String, dynamic>>();
      } else if (role == 'doctor') {
        final result = await _client
            .from('conversations')
            .select()
            .eq('doctor_id', userId)
            .order('created_at', ascending: false);
        rows = (result as List).cast<Map<String, dynamic>>();
      } else {
        final result = await _client
            .from('conversations')
            .select()
            .or('patient_id.eq.$userId,doctor_id.eq.$userId')
            .order('created_at', ascending: false);
        rows = (result as List).cast<Map<String, dynamic>>();
      }

      if (rows.isEmpty) return [];

      final otherIds = <String>{};
      for (final r in rows) {
        otherIds.add(
          r['patient_id'] as String == userId
              ? r['doctor_id'] as String
              : r['patient_id'] as String,
        );
      }

      final allProfiles =
          await _client.from('profiles').select('id, full_name, avatar_url, role');
      final nameMap = <String, String>{};
      final avatarMap = <String, String?>{};
      final roleMap = <String, String>{};
      for (final p in allProfiles) {
        final id = p['id'] as String;
        if (otherIds.contains(id)) {
          nameMap[id] = p['full_name'] as String? ?? 'User';
          avatarMap[id] = p['avatar_url'] as String?;
          roleMap[id] = p['role'] as String? ?? 'patient';
        }
      }

      final lastMsgMap = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final cid = r['id'] as String;
        try {
          final result = await _client
              .from('messages')
              .select('content, created_at, sender_id, is_read, is_deleted')
              .eq('conversation_id', cid)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (result != null) {
            lastMsgMap[cid] = Map<String, dynamic>.from(result);
          }
        } catch (e) {
          developer.log(
            'getUserConversations lastMessage error conversation=$cid: $e',
            name: 'ChatRepositoryImpl',
          );
        }
      }

      final conversationIds = rows.map((r) => r['id'] as String).toList();
      final unreadMap = <String, int>{};
      try {
        final unreadResult = await _client
            .from('messages')
            .select('conversation_id')
            .eq('is_read', false)
            .neq('sender_id', userId)
            .inFilter('conversation_id', conversationIds);
        for (final r in (unreadResult as List).cast<Map<String, dynamic>>()) {
          final cid = r['conversation_id'] as String;
          unreadMap[cid] = (unreadMap[cid] ?? 0) + 1;
        }
      } catch (e) {
        developer.log(
          'getUserConversations unreadCount error: $e',
          name: 'ChatRepositoryImpl',
        );
      }

      return rows.map((r) {
        final cid = r['id'] as String;
        final otherId = r['patient_id'] as String == userId
            ? r['doctor_id'] as String
            : r['patient_id'] as String;
        final last = lastMsgMap[cid];
        final lastMsgIsDeleted = last?['is_deleted'] as bool? ?? false;
        return ConversationData(
          id: cid,
          otherParticipantId: otherId,
          otherParticipantName: nameMap[otherId] ?? 'User',
          otherParticipantRole: roleMap[otherId] ?? 'patient',
          otherParticipantAvatarUrl: avatarMap[otherId],
          lastMessagePreview: lastMsgIsDeleted
              ? 'This message was deleted'
              : last?['content'] as String?,
          lastMessageAt: parseSupabaseTimestamp(last?['created_at'] as String?),
          createdAt: parseSupabaseTimestamp(r['created_at'] as String) ?? DateTime.now(),
          unreadCount: unreadMap[cid] ?? 0,
          lastMessageSenderId: last?['sender_id'] as String?,
          lastMessageIsRead: last?['is_read'] as bool?,
          lastMessageIsDeleted: lastMsgIsDeleted,
          isTyping: false,
        );
      }).toList();
    } catch (e) {
      developer.log(
        'getUserConversations error: $e',
        name: 'ChatRepositoryImpl',
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      var query = _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId);

      if (before != null) {
        query = query.lt('created_at', before);
      }

      final result = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final list = (result as List).cast<Map<String, dynamic>>();
      return list.reversed.toList();
    } catch (e) {
      developer.log(
        'getMessages error: $e',
        name: 'ChatRepositoryImpl',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      final inserted = await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      }).select().single();

      return Map<String, dynamic>.from(inserted);
    } catch (e) {
      developer.log(
        'sendMessage error: $e',
        name: 'ChatRepositoryImpl',
      );
      rethrow;
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .or('is_read.is.null,is_read.eq.false');
    } catch (e) {
      developer.log(
        'markMessagesAsRead error: $e',
        name: 'ChatRepositoryImpl',
      );
    }
  }

  @override
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> payload) onNewMessage,
    void Function(Map<String, dynamic> payload)? onMessageUpdate,
  }) {
    final channel = _client.channel('messages:$conversationId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'conversation_id',
        type: PostgresChangeFilterType.eq,
        value: conversationId,
      ),
      callback: (payload) {
        onNewMessage(Map<String, dynamic>.from(payload.newRecord));
      },
    );

    if (onMessageUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          column: 'conversation_id',
          type: PostgresChangeFilterType.eq,
          value: conversationId,
        ),
        callback: (payload) {
          onMessageUpdate(Map<String, dynamic>.from(payload.newRecord));
        },
      );
    }

    channel.subscribe();
    return channel;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
    } catch (e) {
      developer.log('deleteMessage error: $e', name: 'ChatRepositoryImpl');
      rethrow;
    }
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {
    try {
      await channel.unsubscribe();
    } catch (e) {
      developer.log(
        'unsubscribe error: $e',
        name: 'ChatRepositoryImpl',
      );
    }
  }
}

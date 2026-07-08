import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/repositories/chat_repository.dart';

part 'conversations_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  final ChatRepository _repository;
  final String userId;
  final String role;
  RealtimeChannel? _channel;
  final Map<String, RealtimeChannel> _typingChannels = {};
  final Map<String, Timer> _typingTimers = {};

  ConversationsCubit({
    required ChatRepository repository,
    required this.userId,
    required this.role,
  })  : _repository = repository,
        super(const ConversationsInitial());

  Future<void> loadConversations() async {
    emit(const ConversationsLoading());
    try {
      final conversations = await _repository.getUserConversations(
        userId: userId,
        role: role,
      );
      emit(ConversationsLoaded(conversations));
      _subscribeToNewMessages();
      _subscribeToAllTyping();
    } catch (e) {
      developer.log(
        'ConversationsCubit.loadConversations error: $e',
        name: 'ConversationsCubit',
      );
      emit(ConversationsError('Failed to load conversations'));
    }
  }

  void _subscribeToNewMessages() {
    _channel?.unsubscribe();
    if (state is! ConversationsLoaded) return;

    final channel = Supabase.instance.client.channel('messages:all');
    _channel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final current = state;
        if (current is! ConversationsLoaded) return;

        final record = payload.newRecord;
        final cid = record['conversation_id'] as String?;
        final content = record['content'] as String?;
        final createdAt = record['created_at'] as String?;
        final senderId = record['sender_id'] as String?;
        final isRead = record['is_read'] as bool?;
        final isDeleted = record['is_deleted'] as bool?;
        if (cid == null) return;

        // Check if conversation already exists in list
        final exists = current.conversations.any((c) => c.id == cid);
        if (!exists) {
          loadConversations();
          return;
        }

        final updated = current.conversations.map((c) {
          if (c.id != cid) return c;
          final isMe = senderId == userId;
          final msgDeleted = isDeleted == true;
          return ConversationData(
            id: c.id,
            otherParticipantId: c.otherParticipantId,
            otherParticipantName: c.otherParticipantName,
            otherParticipantAvatarUrl: c.otherParticipantAvatarUrl,
            otherParticipantRole: c.otherParticipantRole,
            lastMessagePreview: msgDeleted
                ? 'This message was deleted'
                : content,
            lastMessageAt: parseSupabaseTimestamp(createdAt),
            createdAt: c.createdAt,
            unreadCount: isMe ? c.unreadCount : c.unreadCount + 1,
            lastMessageSenderId: senderId,
            lastMessageIsRead: isMe ? true : (isRead ?? false),
            lastMessageIsDeleted: msgDeleted,
            isTyping: false,
          );
        }).toList();

        final sorted = List<ConversationData>.from(updated)
          ..sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });

        emit(ConversationsLoaded(sorted));
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final current = state;
        if (current is! ConversationsLoaded) return;

        final record = payload.newRecord;
        final cid = record['conversation_id'] as String?;
        if (cid == null) return;

        final isDeleted = record['is_deleted'] as bool?;
        final isRead = record['is_read'] as bool?;
        final senderId = record['sender_id'] as String?;
        final createdAt = record['created_at'] as String?;
        final deletedAt = parseSupabaseTimestamp(createdAt);

        final updated = current.conversations.map((c) {
          if (c.id != cid) return c;

          bool changed = false;
          String? preview = c.lastMessagePreview;
          bool deleted = c.lastMessageIsDeleted;
          int unread = c.unreadCount;
          bool? lastIsRead = c.lastMessageIsRead;

          // Handle is_deleted update
          if (isDeleted == true &&
              deletedAt != null &&
              c.lastMessageAt != null &&
              deletedAt.isAtSameMomentAs(c.lastMessageAt!)) {
            preview = 'This message was deleted';
            deleted = true;
            changed = true;
          }

          // Handle is_read update
          if (isRead == true && senderId != userId) {
            if (c.unreadCount > 0) {
              unread = c.unreadCount - 1;
              changed = true;
            }
            if (c.lastMessageSenderId == senderId) {
              lastIsRead = true;
              changed = true;
            }
          }

          if (!changed) return c;

          return ConversationData(
            id: c.id,
            otherParticipantId: c.otherParticipantId,
            otherParticipantName: c.otherParticipantName,
            otherParticipantAvatarUrl: c.otherParticipantAvatarUrl,
            otherParticipantRole: c.otherParticipantRole,
            lastMessagePreview: preview,
            lastMessageAt: c.lastMessageAt,
            createdAt: c.createdAt,
            unreadCount: unread,
            lastMessageSenderId: c.lastMessageSenderId,
            lastMessageIsRead: lastIsRead,
            lastMessageIsDeleted: deleted,
            isTyping: c.isTyping,
          );
        }).toList();

        emit(ConversationsLoaded(updated));
      },
    );

    channel.subscribe();
  }

  void _subscribeToAllTyping() {
    _unsubscribeAllTyping();
    final current = state;
    if (current is! ConversationsLoaded) return;

    for (final c in current.conversations) {
      _subscribeToTypingChannel(c.id);
    }
  }

  void _subscribeToTypingChannel(String conversationId) {
    if (_typingChannels.containsKey(conversationId)) return;

    final channel = Supabase.instance.client.channel(
      'typing:$conversationId',
      opts: const RealtimeChannelConfig(self: false),
    );
    _typingChannels[conversationId] = channel;

    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final typingEvent = payload['typing_event'] as String?;
        final senderId = payload['sender_id'] as String?;
        if (senderId == null || senderId == userId) return;

        if (typingEvent == 'start') {
          _typingTimers[conversationId]?.cancel();
          _typingTimers[conversationId] = Timer(
            const Duration(seconds: 5),
            () => _setTyping(conversationId, false),
          );
          _setTyping(conversationId, true);
        } else if (typingEvent == 'stop') {
          _typingTimers[conversationId]?.cancel();
          _typingTimers.remove(conversationId);
          _setTyping(conversationId, false);
        }
      },
    );

    channel.subscribe();
  }

  void _setTyping(String conversationId, bool isTyping) {
    final current = state;
    if (current is! ConversationsLoaded) return;

    final updated = current.conversations.map((c) {
      if (c.id != conversationId) return c;
      if (c.isTyping == isTyping) return c;
      return ConversationData(
        id: c.id,
        otherParticipantId: c.otherParticipantId,
        otherParticipantName: c.otherParticipantName,
        otherParticipantAvatarUrl: c.otherParticipantAvatarUrl,
        otherParticipantRole: c.otherParticipantRole,
        lastMessagePreview: c.lastMessagePreview,
        lastMessageAt: c.lastMessageAt,
        createdAt: c.createdAt,
        unreadCount: c.unreadCount,
        lastMessageSenderId: c.lastMessageSenderId,
        lastMessageIsRead: c.lastMessageIsRead,
        lastMessageIsDeleted: c.lastMessageIsDeleted,
        isTyping: isTyping,
      );
    }).toList();

    emit(ConversationsLoaded(updated));
  }

  void _unsubscribeAllTyping() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    for (final channel in _typingChannels.values) {
      channel.unsubscribe();
    }
    _typingChannels.clear();
  }

  @override
  Future<void> close() async {
    _unsubscribeAllTyping();
    await _channel?.unsubscribe();
    return super.close();
  }
}

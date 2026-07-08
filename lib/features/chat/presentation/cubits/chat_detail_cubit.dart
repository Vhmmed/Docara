import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_detail_state.dart';

class ChatDetailCubit extends Cubit<ChatDetailState> {
  final ChatRepository _repository;
  final String conversationId;
  final String currentUserId;
  RealtimeChannel? _channel;
  bool _hasMore = true;
  static const int _pageSize = 50;

  ChatDetailCubit({
    required ChatRepository repository,
    required this.conversationId,
    required this.currentUserId,
  })  : _repository = repository,
        super(const ChatDetailInitial());

  Future<void> loadMessages() async {
    _hasMore = true;
    emit(const ChatDetailLoading());
    try {
      final messages = await _repository.getMessages(
        conversationId,
        limit: _pageSize,
      );
      _hasMore = messages.length >= _pageSize;
      emit(ChatDetailLoaded(messages));
      _markAsRead();
      _subscribe();
    } catch (e) {
      developer.log(
        'ChatDetailCubit.loadMessages error: $e',
        name: 'ChatDetailCubit',
      );
      emit(const ChatDetailError('Failed to load messages'));
    }
  }

  Future<void> loadMoreMessages() async {
    final current = state;
    if (current is! ChatDetailLoaded) return;
    if (!_hasMore || current.isLoadingMore) return;
    if (current.messages.isEmpty) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final oldest = current.messages.first;
      final before = oldest['created_at'] as String?;
      if (before == null) {
        emit(current.copyWith(isLoadingMore: false));
        return;
      }

      final older = await _repository.getMessages(
        conversationId,
        limit: _pageSize,
        before: before,
      );
      _hasMore = older.length >= _pageSize;

      final all = [...older, ...current.messages];
      emit(ChatDetailLoaded(all));
    } catch (e) {
      developer.log(
        'ChatDetailCubit.loadMoreMessages error: $e',
        name: 'ChatDetailCubit',
      );
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _markAsRead() async {
    await _repository.markMessagesAsRead(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
  }

  void _subscribe() {
    _channel = _repository.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: (payload) {
        final current = state;
        if (current is! ChatDetailLoaded) return;
        if (current.messages.any((m) => m['id'] == payload['id'])) return;

        final updated = [...current.messages, payload];
        emit(ChatDetailLoaded(updated));

        final senderId = payload['sender_id'] as String?;
        if (senderId != currentUserId) {
          _markAsRead();
        }
      },
      onMessageUpdate: (payload) {
        final current = state;
        if (current is! ChatDetailLoaded) return;
        final updatedId = payload['id'] as String?;
        if (updatedId == null) return;

        final updated = current.messages.map((m) {
          return m['id'] == updatedId
              ? Map<String, dynamic>.from(payload)
              : m;
        }).toList();

        emit(ChatDetailLoaded(updated));
      },
    );
  }

  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    final optimistic = <String, dynamic>{
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'content': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_read': false,
    };

    final updated = [...current.messages, optimistic];
    emit(ChatDetailLoaded(updated));

    try {
      final inserted = await _repository.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        content: text,
      );

      final afterInsert = updated.map((m) {
        if (m['id'] == optimistic['id']) {
          return Map<String, dynamic>.from(inserted);
        }
        return m;
      }).toList();

      emit(ChatDetailLoaded(afterInsert));
    } catch (e) {
      developer.log(
        'ChatDetailCubit.sendMessage error: $e',
        name: 'ChatDetailCubit',
      );
      final failedMessage = Map<String, dynamic>.from(optimistic)
        ..['status'] = 'failed';
      final withFailed = current.messages.map((m) {
        return m['id'] == optimistic['id'] ? failedMessage : m;
      }).toList();
      emit(ChatDetailLoaded(
        withFailed,
        snackbarMessage: 'Message failed to send',
      ));
    }
  }

  Future<void> retryMessage(String localId) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    final failedMsg = current.messages
        .where((m) => m['id'] == localId)
        .firstOrNull;
    if (failedMsg == null) return;
    final text = failedMsg['content'] as String? ?? '';
    if (text.isEmpty) return;

    final without = current.messages
        .where((m) => m['id'] != localId)
        .toList();
    emit(ChatDetailLoaded(without));
    await sendMessage(text);
  }

  Future<void> deleteMessage(String messageId) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    final originalMsg = current.messages.firstWhere(
      (m) => m['id'] == messageId,
      orElse: () => <String, dynamic>{},
    );
    if (originalMsg.isEmpty) return;

    final updated = current.messages.map((m) {
      if (m['id'] == messageId) {
        return Map<String, dynamic>.from(m)..['is_deleted'] = true;
      }
      return m;
    }).toList();
    emit(ChatDetailLoaded(updated));

    try {
      await _repository.deleteMessage(messageId);
    } catch (e) {
      final reverted = current.messages.map((m) {
        if (m['id'] == messageId) return originalMsg;
        return m;
      }).toList();
      emit(ChatDetailLoaded(
        reverted,
        snackbarMessage: 'Failed to delete message',
      ));
      developer.log(
        'ChatDetailCubit.deleteMessage error: $e',
        name: 'ChatDetailCubit',
      );
    }
  }

  void clearSnackbar() {
    final current = state;
    if (current is! ChatDetailLoaded) return;
    emit(current.copyWith(clearSnackbar: true));
  }

  @override
  Future<void> close() async {
    await _channel?.unsubscribe();
    return super.close();
  }
}

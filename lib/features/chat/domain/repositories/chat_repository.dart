import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationData {
  final String id;
  final String otherParticipantId;
  final String otherParticipantName;
  final String otherParticipantRole;
  final String? otherParticipantAvatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;
  final String? lastMessageSenderId;
  final bool? lastMessageIsRead;
  final bool lastMessageIsDeleted;
  final bool isTyping;

  const ConversationData({
    required this.id,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.otherParticipantRole,
    this.otherParticipantAvatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = 0,
    this.lastMessageSenderId,
    this.lastMessageIsRead,
    this.lastMessageIsDeleted = false,
    this.isTyping = false,
  });
}

abstract class ChatRepository {
  Future<Map<String, dynamic>> getOrCreateConversation({
    required String patientId,
    required String doctorId,
  });

  Future<List<ConversationData>> getUserConversations({
    required String userId,
    required String role,
  });

  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  });

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  });

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  });

  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> payload) onNewMessage,
    void Function(Map<String, dynamic> payload)? onMessageUpdate,
  });

  Future<void> deleteMessage(String messageId);

  Future<void> unsubscribe(RealtimeChannel channel);
}

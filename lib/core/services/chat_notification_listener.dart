import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/services/local_notification_service.dart';
import 'package:medical_booking_app/core/utils/doctor_display_name.dart';
import 'package:medical_booking_app/features/chat/presentation/widgets/chat_detail_page.dart';

class ChatNotificationListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ChatNotificationListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  static final _activeConversations = <String>{};

  static void enterConversation(String id) => _activeConversations.add(id);
  static void leaveConversation(String id) => _activeConversations.remove(id);

  @override
  State<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends State<ChatNotificationListener> {
  RealtimeChannel? _channel;
  String? _currentUserId;
  int _nextNotificationId = 0;
  StreamSubscription<AuthState>? _authSubscription;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    developer.log(
      'INIT: ChatNotificationListener mounted, current auth user id=${Supabase.instance.client.auth.currentUser?.id}',
      name: 'ChatNotificationListener',
    );
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_currentUserId != null) _subscribe();
    if (_currentUserId == null) {
      developer.log(
        'INIT: No user signed in yet — will subscribe when auth state changes',
        name: 'ChatNotificationListener',
      );
    }

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      developer.log(
        'AUTH: event=${event.event} newSessionUserId=${event.session?.user.id} oldCurrentUserId=$_currentUserId',
        name: 'ChatNotificationListener',
      );
      final newId = event.session?.user.id;
      if (newId != _currentUserId) {
        developer.log(
          'AUTH: userId changed, old=$_currentUserId new=$newId — resubscribing',
          name: 'ChatNotificationListener',
        );
        if (_currentUserId != null) {
          _channel?.unsubscribe();
        }
        _currentUserId = newId;
        if (newId != null) _subscribe();
      }
    });

    LocalNotificationService.onNotificationTap.addListener(_onNotificationTap);
    final pending = LocalNotificationService.onNotificationTap.value;
    if (pending != null) {
      developer.log('INIT: Pending notification tap found, navigating',
          name: 'ChatNotificationListener');
      _navigateToChat(pending);
    }
  }

  void _onNotificationTap() {
    final payload = LocalNotificationService.onNotificationTap.value;
    if (payload == null) return;
    LocalNotificationService.onNotificationTap.value = null;
    _navigateToChat(payload);
  }

  void _showInAppBanner({
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    _bannerEntry?.remove();
    _bannerTimer?.cancel();
    if (!mounted) return;

    try {
      _bannerEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: () {
                  _bannerEntry?.remove();
                  _bannerEntry = null;
                  _bannerTimer?.cancel();
                  onTap();
                },
                child: _InAppBannerContent(title: title, body: body),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_bannerEntry!);
    } catch (e) {
      developer.log('InAppBanner insert error: $e', name: 'ChatNotificationListener');
      _bannerEntry = null;
    }

    _bannerTimer = Timer(const Duration(seconds: 4), () {
      _bannerEntry?.remove();
      _bannerEntry = null;
    });
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client.channel('chat_notifications_global');
    developer.log(
      'STEP 1: Creating channel chat_notifications_global, currentUserId=$_currentUserId',
      name: 'ChatNotificationListener',
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        developer.log(
          'STEP 2: Realtime INSERT payload received: ${jsonEncode(payload.newRecord)}',
          name: 'ChatNotificationListener',
        );

        if (_currentUserId == null) {
          developer.log(
            'STEP 2a: _currentUserId is null — skipping',
            name: 'ChatNotificationListener',
          );
          return;
        }

        final record = payload.newRecord;
        final senderId = record['sender_id'] as String?;
        final conversationId = record['conversation_id'] as String?;
        final content = record['content'] as String? ?? '';

        developer.log(
          'STEP 3: senderId=$senderId currentUserId=$_currentUserId conversationId=$conversationId',
          name: 'ChatNotificationListener',
        );

        if (senderId == null) {
          developer.log(
              'STEP 3a: senderId is null — skipping',
              name: 'ChatNotificationListener');
          return;
        }

        if (senderId == _currentUserId) {
          developer.log(
            'STEP 3b: senderId == currentUserId (own message) — skipping',
            name: 'ChatNotificationListener',
          );
          return;
        }

        if (conversationId == null) {
          developer.log(
              'STEP 3c: conversationId is null — skipping',
              name: 'ChatNotificationListener');
          return;
        }

        final isActive =
            ChatNotificationListener._activeConversations.contains(conversationId);
        developer.log(
          'STEP 4: _activeConversations=${ChatNotificationListener._activeConversations} isActive=$isActive',
          name: 'ChatNotificationListener',
        );

        if (isActive) {
          developer.log(
            'STEP 4a: conversation is active (user viewing it) — skipping',
            name: 'ChatNotificationListener',
          );
          return;
        }

        final truncated =
            content.length > 50 ? '${content.substring(0, 47)}...' : content;

        try {
          developer.log(
            'STEP 5: Fetching sender profile for id=$senderId',
            name: 'ChatNotificationListener',
          );

          final senderProfile = await Supabase.instance.client
              .from('profiles')
              .select('full_name, avatar_url, role')
              .eq('id', senderId)
              .single();

          developer.log(
            'STEP 6: senderProfile query returned: $senderProfile',
            name: 'ChatNotificationListener',
          );

          final senderName =
              (senderProfile['full_name'] as String?) ?? 'Someone';
          final senderRole = (senderProfile['role'] as String?) ?? 'patient';
          final senderAvatar = senderProfile['avatar_url'] as String?;
          final displayName = senderRole == 'doctor'
              ? doctorDisplayName(senderName)
              : toTitleCase(senderName);

          final notificationPayload = jsonEncode({
            'conversation_id': conversationId,
            'contact_id': senderId,
            'contact_name': senderName,
            'contact_avatar_url': senderAvatar,
            'sender_role': senderRole,
          });

          developer.log(
            'STEP 7: Calling LocalNotificationService.show() — title="New message from $displayName" body="$truncated" payload=$notificationPayload',
            name: 'ChatNotificationListener',
          );

          await LocalNotificationService.show(
            id: _nextNotificationId++,
            title: 'New message from $displayName',
            body: truncated,
            payload: notificationPayload,
          );

          developer.log(
            'STEP 8: LocalNotificationService.show() completed successfully',
            name: 'ChatNotificationListener',
          );

          _showInAppBanner(
            title: 'New message from $displayName',
            body: truncated,
            onTap: () => _navigateToChat(notificationPayload),
          );
        } catch (e) {
          developer.log(
            'ERROR in message handler: $e',
            name: 'ChatNotificationListener',
            error: e,
          );
        }
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) async {
        if (_currentUserId == null) return;
        final record = payload.newRecord;
        final targetUserId = record['user_id'] as String?;
        if (targetUserId != _currentUserId) return;

        final title = record['title'] as String? ?? 'Notification';
        final body = record['body'] as String? ?? '';

        try {
          await LocalNotificationService.show(
            id: _nextNotificationId++,
            title: title,
            body: body,
            payload: jsonEncode({'notification_id': record['id'] as String?}),
          );
        } catch (e) {
          developer.log(
            'ERROR in notification handler: $e',
            name: 'ChatNotificationListener',
          );
        }

        _showInAppBanner(
          title: title,
          body: body,
          onTap: () {},
        );
      },
    );

    _channel!.subscribe((status, error) {
      developer.log(
        'STEP 1b: Channel subscribe status=$status error=$error',
        name: 'ChatNotificationListener',
      );
    });
  }

  void _navigateToChat(String payloadJson) {
    try {
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;
      final conversationId = data['conversation_id'] as String?;
      final contactId = data['contact_id'] as String?;
      final contactName = data['contact_name'] as String?;
      final contactAvatarUrl = data['contact_avatar_url'] as String?;
      final senderRole = data['sender_role'] as String?;

      if (conversationId == null ||
          contactId == null ||
          _currentUserId == null) {
        return;
      }

      widget.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conversationId,
            currentUserId: _currentUserId!,
            contactName: contactName ?? 'Someone',
            contactId: contactId,
            contactAvatarUrl: contactAvatarUrl,
            contactRole: senderRole,
          ),
        ),
      );
    } catch (e) {
      developer.log(
        'Failed to navigate from notification tap: $e',
        name: 'ChatNotificationListener',
      );
    }
  }

  @override
  void dispose() {
    _bannerEntry?.remove();
    _bannerTimer?.cancel();
    LocalNotificationService.onNotificationTap
        .removeListener(_onNotificationTap);
    _authSubscription?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _InAppBannerContent extends StatelessWidget {
  final String title;
  final String body;

  const _InAppBannerContent({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF6C63FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

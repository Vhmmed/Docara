import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/unread_count_cubit.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../widgets/loading/loading_widgets.dart';
import '../../../../core/utils/doctor_display_name.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubits/conversations_cubit.dart';
import '../widgets/chat_detail_page.dart';
import '../widgets/conversation_tile.dart';

class MessagesPage extends StatefulWidget {
  final String roleId;

  const MessagesPage({super.key, required this.roleId});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _searchQuery = '';
  late ConversationsCubit _cubit;
  late String _currentUserId;
  StreamSubscription<ConversationsState>? _unreadSubscription;
  StreamSubscription<Set<String>>? _presenceSubscription;
  Set<String> _onlineUsers = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final repository = sl<ChatRepository>();
    _cubit = ConversationsCubit(
      repository: repository,
      userId: _currentUserId,
      role: widget.roleId,
    );
    _unreadSubscription = _cubit.stream.listen(_onConversationsStateChanged);
    _presenceSubscription =
        sl<PresenceService>().onlineUsers.listen((online) {
      setState(() => _onlineUsers = online);
    });
    _cubit.loadConversations();
  }

  void _onConversationsStateChanged(ConversationsState state) {
    if (state is ConversationsLoaded) {
      final total = state.conversations.fold(0, (sum, c) => sum + c.unreadCount);
      sl<UnreadCountCubit>().setCount(total);
    }
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _presenceSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  String _formatTimestamp(DateTime? dt) => relativeDate(dt);

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 48, bottom: 16, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Your conversations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
            onTap: () {
              setState(() => _searchQuery = '');
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const Gap(26),
            _buildAppBar(),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                bloc: _cubit,
                builder: (context, state) {
                  return switch (state) {
                    ConversationsInitial() || ConversationsLoading() =>
                        _buildLoadingState(),
                    ConversationsError(:final message) => _buildErrorState(message),
                    ConversationsLoaded(:final conversations) =>
                        _buildConversationList(conversations),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBouncingDots(),
          SizedBox(height: 16),
          Text(
            'Loading conversations...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const Gap(12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            TextButton(
              onPressed: () => _cubit.loadConversations(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(List<ConversationData> conversations) {
    final filtered = _searchQuery.isEmpty
        ? conversations
        : conversations
        .where((c) =>
        c.otherParticipantName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const Gap(20),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Gap(8),
            Text(
              'Start a conversation with your healthcare provider',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const Gap(16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Gap(8),
            Text(
              'Try adjusting your search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cubit.loadConversations(),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final conv = filtered[index];
          final displayName = conv.otherParticipantRole == 'doctor'
              ? doctorDisplayName(conv.otherParticipantName)
              : toTitleCase(conv.otherParticipantName);

          return Column(
            children: [
              if (index == 0) const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                  child: ConversationTile(
                    name: displayName,
                    rawName: conv.otherParticipantName,
                    avatarUrl: conv.otherParticipantAvatarUrl,
                    lastMessage: conv.lastMessagePreview ?? '',
                    timestamp: _formatTimestamp(conv.lastMessageAt),
                    unreadCount: conv.unreadCount,
                    lastMessageSenderId: conv.lastMessageSenderId,
                    lastMessageIsRead: conv.lastMessageIsRead,
                    currentUserId: _currentUserId,
                    isOnline: _onlineUsers.contains(conv.otherParticipantId),
                    isDeleted: conv.lastMessageIsDeleted,
                    isTyping: conv.isTyping,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          conversationId: conv.id,
                          currentUserId: _currentUserId,
                          contactName: displayName,
                          contactId: conv.otherParticipantId,
                          contactAvatarUrl: conv.otherParticipantAvatarUrl,
                          contactRole: conv.otherParticipantRole,
                        ),
                      ),
                    );
                    if (mounted) _cubit.loadConversations();
                  },
                ),
              ),
              const Gap(10),
              Container(
                margin: const EdgeInsets.only(left: 62),
                height: 0.6,
                color: Colors.grey.shade300,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Helper function
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
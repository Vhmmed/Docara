import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../widgets/loading/loading_widgets.dart';
import '../../../../core/services/chat_notification_listener.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/utils/doctor_display_name.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubits/chat_detail_cubit.dart';
import 'chat_wallpaper_painter.dart';
import 'message_bubble.dart';
import 'date_separator.dart';
import 'typing_indicator.dart';

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String contactName;
  final String contactId;
  final String? contactAvatarUrl;
  final String? contactRole;
  final String? contactRawName;
  final DateTime? contactLastSeenAt;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.contactName,
    required this.contactId,
    this.contactAvatarUrl,
    this.contactRole,
    this.contactRawName,
    this.contactLastSeenAt,
  });

  String get displayName {
    if (contactRole == 'doctor') {
      return doctorDisplayName(contactName);
    }
    return toTitleCase(contactName);
  }

  String get rawNameForInitial => contactRawName ?? contactName;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late ChatDetailCubit _cubit;
  bool _hasText = false;
  bool _isNearBottom = true;
  bool _isFirstLoad = true;
  double _lastKeyboardHeight = 0;
  bool _isContactOnline = false;
  DateTime? _contactLastSeen;
  String? _fetchedContactRole;
  String? _fetchedContactAvatarUrl;
  StreamSubscription<Set<String>>? _presenceSubscription;
  RealtimeChannel? _typingChannel;
  Timer? _typingDebounceTimer;
  Timer? _typingSafetyTimer;
  bool _isTyping = false;
  bool _isContactTyping = false;

  String get _effectiveDisplayName {
    final role = _fetchedContactRole ?? widget.contactRole;
    if (role == 'doctor') {
      return doctorDisplayName(widget.contactName);
    }
    return toTitleCase(widget.contactName);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatNotificationListener.enterConversation(widget.conversationId);
    _controller.addListener(_onTypingChanged);
    _scrollController.addListener(_onScrollChanged);
    final repository = sl<ChatRepository>();
    _cubit = ChatDetailCubit(
      repository: repository,
      conversationId: widget.conversationId,
      currentUserId: widget.currentUserId,
    );
    _contactLastSeen = widget.contactLastSeenAt;
    debugPrint('[ChatDetailPage] init: contactId=${widget.contactId}');
    _presenceSubscription =
        sl<PresenceService>().onlineUsers.listen((online) {
      final nowOnline = online.contains(widget.contactId);
      debugPrint(
        '[ChatDetailPage] presence update: online=$online '
        'contactId=${widget.contactId} isOnline=$nowOnline '
        'rebuild=$_isContactOnline->$nowOnline',
      );
      if (!mounted) return;
      setState(() => _isContactOnline = nowOnline);
    });
    _isContactOnline = sl<PresenceService>().isOnline(widget.contactId);
    debugPrint('[ChatDetailPage] initial snapshot: isOnline=$_isContactOnline');
    if (_contactLastSeen == null) {
      _fetchLastSeen();
    }
    if (widget.contactRole == null) {
      _fetchContactProfile();
    }
    _setupTypingChannel();
    _cubit.loadMessages();
  }

  Future<void> _fetchLastSeen() async {
    try {
      debugPrint('[ChatDetailPage] _fetchLastSeen for contactId=${widget.contactId} me=${Supabase.instance.client.auth.currentUser?.id}');
      final result = await Supabase.instance.client
          .from('profiles')
          .select('last_seen_at')
          .eq('id', widget.contactId)
          .maybeSingle();
      debugPrint('[ChatDetailPage] _fetchLastSeen result=$result');
      if (result != null && mounted) {
        final raw = result['last_seen_at'] as String?;
        debugPrint('[ChatDetailPage] _fetchLastSeen raw=$raw');
        if (raw != null) {
          final parsed = parseSupabaseTimestamp(raw);
          debugPrint('[ChatDetailPage] _fetchLastSeen parsed=$parsed');
          setState(() => _contactLastSeen = parsed);
        }
      }
    } catch (e) {
      debugPrint('[ChatDetailPage] _fetchLastSeen error: $e');
    }
  }

  void _setupTypingChannel() {
    _typingChannel = Supabase.instance.client.channel(
      'typing:${widget.conversationId}',
      opts: const RealtimeChannelConfig(self: false),
    );
    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final typingEvent = payload['typing_event'] as String?;
        final senderId = payload['sender_id'] as String?;
        if (senderId == null || senderId == widget.currentUserId) return;
        debugPrint(
          '[Typing] received typing_event=$typingEvent sender=$senderId',
        );
        if (typingEvent == 'start') {
          _typingSafetyTimer?.cancel();
          _typingSafetyTimer = Timer(
            const Duration(seconds: 5),
            () {
              if (!mounted) return;
              setState(() => _isContactTyping = false);
            },
          );
          if (!mounted) return;
          setState(() => _isContactTyping = true);
          if (_isNearBottom) {
            _scrollToBottom(animated: true);
          }
        } else if (typingEvent == 'stop') {
          _typingSafetyTimer?.cancel();
          if (!mounted) return;
          setState(() => _isContactTyping = false);
        }
      },
    );
    _typingChannel!.subscribe((status, err) {
      debugPrint('[Typing] subscribe: status=$status err=$err');
    });
  }

  void _sendTypingEvent(String typingEvent) {
    if (_typingChannel == null) return;
    _typingChannel!.sendBroadcastMessage(
      event: 'typing',
      payload: {'typing_event': typingEvent, 'sender_id': widget.currentUserId},
    );
    debugPrint('[Typing] sent typing_event=$typingEvent');
  }

  void _onTypingChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    if (!hasText) return;

    if (!_isTyping) {
      _isTyping = true;
      _sendTypingEvent('start');
    }

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      _sendTypingEvent('stop');
    });
  }

  void _cancelTyping() {
    _typingDebounceTimer?.cancel();
    _typingSafetyTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      _sendTypingEvent('stop');
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final currentHeight = MediaQuery.of(context).viewInsets.bottom;
      if (currentHeight == _lastKeyboardHeight) return;
      _lastKeyboardHeight = currentHeight;
      if (!_isNearBottom) return;
      _scrollToBottom(animated: false);
    });
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _isNearBottom = (maxScroll - currentScroll) < 120;

    if (currentScroll <= 40 && !_isFirstLoad) {
      _cubit.loadMoreMessages();
    }
  }

  Future<void> _fetchContactProfile() async {
    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('role, avatar_url')
          .eq('id', widget.contactId)
          .maybeSingle();
      if (result != null && mounted) {
        setState(() {
          _fetchedContactRole = result['role'] as String?;
          _fetchedContactAvatarUrl = result['avatar_url'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatNotificationListener.leaveConversation(widget.conversationId);
    _cancelTyping();
    _typingChannel?.unsubscribe();
    _typingChannel = null;
    _cubit.close();
    _controller.removeListener(_onTypingChanged);
    _scrollController.removeListener(_onScrollChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  void _onDeleteMessage(BuildContext context, String messageId) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Delete message'),
        message: const Text('This message will be deleted for everyone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (dialogCtx) => CupertinoAlertDialog(
                  title: const Text('Delete message'),
                  content: const Text(
                    'Are you sure you want to delete this message?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _cubit.deleteMessage(messageId);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _onSendTap() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _cancelTyping();
    _cubit.sendMessage(text);
    _controller.clear();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || !_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        if ((maxScroll - currentScroll) > 30) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(color: const Color(0xFFF7FAFB)),
          Positioned.fill(
            child: CustomPaint(
              painter: ChatWallpaperPainter(),
            ),
          ),
          Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody()),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 4),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl) != null &&
                            (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl)!.isNotEmpty
                        ? NetworkImage(_fetchedContactAvatarUrl ?? widget.contactAvatarUrl!)
                        : null,
                    child: (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl) == null ||
                            (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl)!.isEmpty
                        ? Text(
                            widget.rawNameForInitial.isNotEmpty
                                ? widget.rawNameForInitial[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _effectiveDisplayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isContactOnline
                              ? 'Online'
                              : _contactLastSeen != null
                                  ? lastSeenText(_contactLastSeen)
                                  : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isContactOnline
                                ? const Color(0xFF22C55E)
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 40,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Video call coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Icon(
                            CupertinoIcons.videocam,
                            color: AppColors.primary,
                            size: 35,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 40,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice call coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Icon(
                            CupertinoIcons.phone,
                            color: AppColors.primary,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final borderColor = _focusNode.hasFocus
        ? AppColors.primary
        : AppColors.border;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {},
                child: const Icon(
                  CupertinoIcons.plus_circle,
                  size: 26,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 38, maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _onSendTap(),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 6),
                      child: GestureDetector(
                        onTap: () {
                        },
                        child: const Icon(
                          CupertinoIcons.mic,
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _hasText ? 36 : 0,
                height: 36,
                curve: Curves.easeOut,
                child: _hasText
                    ? GestureDetector(
                        onTap: _onSendTap,
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_up,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<ChatDetailCubit, ChatDetailState>(
      bloc: _cubit,
      listenWhen: (prev, current) {
        if (current is ChatDetailLoaded && current.snackbarMessage != null) {
          return current.snackbarMessage !=
              (prev is ChatDetailLoaded ? prev.snackbarMessage : null);
        }
        if (current is ChatDetailLoaded && prev is ChatDetailLoading) {
          return true;
        }
        if (current is ChatDetailLoaded && prev is ChatDetailLoaded) {
          final prevLen = prev.messages.length;
          final curLen = current.messages.length;
          if (curLen > prevLen && current.messages.isNotEmpty) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {
        if (state is ChatDetailLoaded && state.snackbarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.snackbarMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _cubit.clearSnackbar();
        }
        if (state is ChatDetailLoaded && state.messages.isNotEmpty) {
          final senderId =
              state.messages.last['sender_id'] as String?;
          final isOwnMessage = senderId == widget.currentUserId;

          // If a real message arrives from the other user,
          // hide the typing indicator
          if (!isOwnMessage && _isContactTyping) {
            _typingSafetyTimer?.cancel();
            setState(() => _isContactTyping = false);
          }

          if (isOwnMessage || _isNearBottom) {
            _scrollToBottom();
          }
        }
      },
      builder: (context, state) {
        if (state is ChatDetailLoaded && state.messages.isNotEmpty && _isFirstLoad) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
            _isFirstLoad = false;
          });
        }
        return switch (state) {
          ChatDetailInitial() || ChatDetailLoading() =>
            const Center(child: AppBouncingDots()),
          ChatDetailError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const Gap(12),
                    Text(
                      message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    TextButton(
                      onPressed: () => _cubit.loadMessages(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ChatDetailLoaded(:final messages, :final isLoadingMore) =>
              _buildMessagesListWithTyping(messages, isLoadingMore: isLoadingMore),
        };
      },
    );
  }

  List<Object> _buildDisplayItems(List<Map<String, dynamic>> messages) {
    final items = <Object>[];
    DateTime? lastDate;
    for (final msg in messages) {
      final createdAt = msg['created_at'] as String?;
      final msgDate = createdAt != null
          ? parseSupabaseTimestamp(createdAt)?.toLocal()
          : null;
      final day = msgDate != null
          ? DateTime(msgDate.year, msgDate.month, msgDate.day)
          : null;
      if (day != null && (lastDate == null || day != lastDate)) {
        items.add(day);
        lastDate = day;
      }
      items.add(msg);
    }
    return items;
  }

  Widget _buildMessagesList(
    List<Map<String, dynamic>> messages, {
    bool isLoadingMore = false,
  }) {
    if (messages.isEmpty && !_isContactTyping) {
      return Center(
        child: Text(
          'No messages yet. Say hello!',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (messages.isEmpty && _isContactTyping) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: 1,
        itemBuilder: (context, index) => _buildTypingRow(),
      );
    }
    final displayItems = _buildDisplayItems(messages);
    final hasLoader = isLoadingMore ? 1 : 0;
    final hasTyping = _isContactTyping ? 1 : 0;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: displayItems.length + hasLoader + hasTyping,
      itemBuilder: (context, index) {
        if (isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final typingIndex = displayItems.length + hasLoader;
        if (hasTyping > 0 && index == typingIndex) {
          return _buildTypingRow();
        }
        final itemIndex = isLoadingMore ? index - 1 : index;
        final item = displayItems[itemIndex];
        if (item is DateTime) {
          return DateSeparator(date: item);
        }
        final msg = item as Map<String, dynamic>;
        final isMe = msg['sender_id'] as String == widget.currentUserId;
        final isLastInGroup = itemIndex == displayItems.length - 1 ||
            (displayItems[itemIndex + 1] is! Map || _isDifferentSender(
              msg['sender_id'] as String?,
              (displayItems[itemIndex + 1] as Map<String, dynamic>)['sender_id'] as String?,
            ));
        final isFirstInGroup = itemIndex == 0 ||
            displayItems[itemIndex - 1] is DateTime ||
            (displayItems[itemIndex - 1] is Map && _isDifferentSender(
              msg['sender_id'] as String?,
              (displayItems[itemIndex - 1] as Map<String, dynamic>)['sender_id'] as String?,
            ));
        final isRead = (msg['is_read'] as bool?) ?? false;
        final isFailed = (msg['status'] as String?) == 'failed';
        final isDeleted = (msg['is_deleted'] as bool?) ?? false;
        final localId = msg['id'] as String? ?? '';
        return MessageBubble(
          text: msg['content'] as String? ?? '',
          time: _formatTime(msg['created_at'] as String?),
          isSentByMe: isMe,
          isRead: isRead,
          isFailed: isFailed,
          isDeleted: isDeleted,
          onRetry: isFailed ? () => _cubit.retryMessage(localId) : null,
          onLongPress: isMe && !isDeleted
              ? () => _onDeleteMessage(context, localId)
              : null,
          isFirstInGroup: isFirstInGroup,
          showTail: isLastInGroup,
          showAvatar: !isMe && isLastInGroup,
          contactAvatarUrl: !isMe && isLastInGroup
              ? widget.contactAvatarUrl
              : null,
          contactInitial: !isMe && isLastInGroup
              ? (widget.rawNameForInitial.isNotEmpty
                      ? widget.rawNameForInitial[0].toUpperCase()
                      : '?')
              : null,
        );
      },
    );
  }

  Widget _buildMessagesListWithTyping(
    List<Map<String, dynamic>> messages, {
    bool isLoadingMore = false,
  }) {
    return _buildMessagesList(messages, isLoadingMore: isLoadingMore);
  }

  Widget _buildTypingRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl) != null &&
                      (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl)!.isNotEmpty
                  ? NetworkImage(_fetchedContactAvatarUrl ?? widget.contactAvatarUrl!)
                  : null,
              child: (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl) == null ||
                      (_fetchedContactAvatarUrl ?? widget.contactAvatarUrl)!.isEmpty
                  ? Text(
                      widget.rawNameForInitial.isNotEmpty
                          ? widget.rawNameForInitial[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8EC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const TypingIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentSender(String? a, String? b) => a != b;

  String _formatTime(String? iso) => messageBubbleTime(iso);
}

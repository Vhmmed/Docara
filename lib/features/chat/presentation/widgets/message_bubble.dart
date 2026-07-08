import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_color.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isSentByMe;
  final bool isRead;
  final bool isFailed;
  final bool isDeleted;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;
  final bool isFirstInGroup;
  final bool showTail;
  final bool showAvatar;
  final String? contactAvatarUrl;
  final String? contactInitial;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isSentByMe,
    required this.isRead,
    this.isFailed = false,
    this.isDeleted = false,
    this.onRetry,
    this.onLongPress,
    required this.isFirstInGroup,
    required this.showTail,
    this.showAvatar = false,
    this.contactAvatarUrl,
    this.contactInitial,
  });

  BorderRadiusGeometry _borderRadius() {
    const r = 20.0;
    const s = 5.0;

    if (isSentByMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(r),
        topRight: isFirstInGroup ? const Radius.circular(r) : const Radius.circular(s),
        bottomLeft: const Radius.circular(r),
        bottomRight: showTail ? const Radius.circular(s) : const Radius.circular(r),
      );
    } else {
      return BorderRadius.only(
        topLeft: isFirstInGroup ? const Radius.circular(r) : const Radius.circular(s),
        topRight: const Radius.circular(r),
        bottomLeft: showTail ? const Radius.circular(s) : const Radius.circular(r),
        bottomRight: const Radius.circular(r),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return _buildDeletedBubble(context);
    }
    final bubbleColor = isSentByMe
        ? (isFailed ? AppColors.error.withValues(alpha: 0.7) : AppColors.primary)
        : const Color(0xFFE8E8EC);
    final textColor = isSentByMe ? Colors.white : AppColors.textPrimary;
    final timeColor = isSentByMe
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: _borderRadius(),
        border: isSentByMe
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFailed)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.error,
                    size: 14,
                    color: isSentByMe
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.error,
                  ),
                ),
              Text(
                time,
                style: TextStyle(color: timeColor, fontSize: 11),
              ),
              if (isSentByMe && !isFailed) ...[
                const SizedBox(width: 4),
                Icon(
                  isRead ? Icons.done_all : Icons.check,
                  size: 14,
                  color: isRead
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final wrappedBubble = onLongPress != null
        ? GestureDetector(
            onLongPress: onLongPress,
            child: bubble,
          )
        : bubble;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 8.0 : 2.0,
        bottom: showTail ? 8.0 : 2.0,
      ),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: contactAvatarUrl != null && contactAvatarUrl!.isNotEmpty
                    ? NetworkImage(contactAvatarUrl!)
                    : null,
                child: contactAvatarUrl == null || contactAvatarUrl!.isEmpty
                    ? Text(
                        contactInitial ?? '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          if (!isSentByMe && !showAvatar) const SizedBox(width: 36),
          Flexible(
            child: isFailed
                ? GestureDetector(
                    onTap: onRetry,
                    child: bubble,
                  )
                : wrappedBubble,
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 8.0 : 2.0,
        bottom: showTail ? 8.0 : 2.0,
      ),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: contactAvatarUrl != null && contactAvatarUrl!.isNotEmpty
                    ? NetworkImage(contactAvatarUrl!)
                    : null,
                child: contactAvatarUrl == null || contactAvatarUrl!.isEmpty
                    ? Text(
                        contactInitial ?? '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          if (!isSentByMe && !showAvatar) const SizedBox(width: 36),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8EC).withValues(alpha: 0.5),
                borderRadius: _borderRadius(),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle,
                    size: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'This message was deleted',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
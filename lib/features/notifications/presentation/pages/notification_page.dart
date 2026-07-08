import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/custom_text.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../chat/presentation/widgets/chat_detail_page.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../cubits/notification_cubit.dart';
import '../cubits/notification_unread_count_cubit.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final NotificationsCubit _cubit;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _cubit = NotificationsCubit(
      repository: sl<NotificationRepository>(),
      userId: _currentUserId ?? '',
      unreadCountCubit: sl<NotificationUnreadCountCubit>(),
    );
    _cubit.loadNotifications();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onNotificationTap(NotificationEntity notification) {
    if (!notification.isRead) {
      _cubit.markAsRead(notification.id);
    }

    switch (notification.type) {
      case 'appointment_booked':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        break;
      case 'appointment_confirmed':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentsPage()),
        );
        break;
      case 'appointment_cancelled':
        final user = Supabase.instance.client.auth.currentUser;
        final role = user?.userMetadata?['role'] as String?;
        if (role == 'doctor') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SchedulePage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentsPage()),
          );
        }
        break;
      case 'message':
        final conversationId =
            notification.data['conversation_id'] as String?;
        final contactId = notification.data['sender_id'] as String?;
        final contactName =
            notification.data['sender_name'] as String? ?? '';
        final contactAvatarUrl =
            notification.data['sender_avatar_url'] as String?;
        final contactRole =
            notification.data['sender_role'] as String?;
        if (conversationId != null && _currentUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailPage(
                conversationId: conversationId,
                currentUserId: _currentUserId!,
                contactName: contactName,
                contactId: contactId ?? '',
                contactAvatarUrl: contactAvatarUrl,
                contactRole: contactRole,
              ),
            ),
          );
        }
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentsPage()),
        );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'appointment_booked':
        return CupertinoIcons.calendar_badge_plus;
      case 'appointment_confirmed':
        return CupertinoIcons.check_mark_circled_solid;
      case 'appointment_cancelled':
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.bell;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'appointment_booked':
        return AppColors.primary;
      case 'appointment_confirmed':
        return const Color(0xFF22C55E);
      case 'appointment_cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.black, size: 25),
        ),
        title: const CustomText(
          text: 'Notifications',
          size: 20,
          weight: FontWeight.w600,
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              final hasUnread = state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _cubit.markAllAsRead(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: CustomText(
                    text: 'Mark all read',
                    size: 14,
                    color: AppColors.primary,
                    weight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (state.status == NotificationsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  CustomText(
                    text: state.error ?? 'Something went wrong',
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _cubit.loadNotifications(),
                    child: const CustomText(
                      text: 'Try Again',
                      color: AppColors.primary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = state.notifications;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bell, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  CustomText(
                    text: 'No notifications yet',
                    size: 18,
                    weight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text: "You'll see notifications here when they arrive",
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _cubit.loadNotifications(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;

                return InkWell(
                  onTap: () => _onNotificationTap(notification),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _colorForType(notification.type)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconForType(notification.type),
                                color: _colorForType(notification.type),
                                size: 22,
                              ),
                            ),
                            if (isUnread)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    relativeDate(notification.createdAt),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: TextStyle(
                                  fontWeight:
                                      isUnread ? FontWeight.w500 : FontWeight.w400,
                                  color: isUnread
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

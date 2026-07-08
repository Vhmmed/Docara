import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/chat/domain/repositories/chat_repository.dart';
import '../../../../features/chat/presentation/widgets/chat_detail_page.dart';
import '../../domain/entities/appointment_entity.dart';

class AppointmentDetailSheet extends StatelessWidget {
  final AppointmentEntity appointment;
  final String currentUserId;
  final void Function(String id)? onCancel;

  const AppointmentDetailSheet({
    super.key,
    required this.appointment,
    required this.currentUserId,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withAlpha(40),
                    backgroundImage: a.avatarUrl != null &&
                            a.avatarUrl!.isNotEmpty
                        ? NetworkImage(a.avatarUrl!)
                        : null,
                    child: a.avatarUrl == null || a.avatarUrl!.isEmpty
                        ? Text(
                            a.doctorName.isNotEmpty
                                ? a.doctorName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.doctorName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            a.specialty,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(a.status)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppointmentEntity.statusLabel(a.status),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _statusColor(a.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _section('Appointment Details'),
              const SizedBox(height: 8),
              _infoRow(CupertinoIcons.calendar, 'Date', a.dateFormatted),
              _infoRow(CupertinoIcons.clock, 'Time', a.timeFormatted),
              if (a.location.isNotEmpty)
                _infoRow(CupertinoIcons.location, 'Location', a.location),
              _infoRow(Icons.attach_money_outlined, 'Fee', a.feeFormatted),
              _infoRow(Icons.confirmation_number_outlined, 'Reference', a.id),
              if (a.notes != null && a.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _section('Notes'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(40),
                    ),
                  ),
                  child: Text(
                    a.notes!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              if (a.status == AppointmentStatus.pending) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context, a.id),
                    icon:
                        const Icon(CupertinoIcons.xmark_circle, size: 18),
                    label: const Text('Cancel Appointment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withAlpha(75)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _messageDoctor(context),
                  icon:
                      const Icon(CupertinoIcons.chat_bubble_2, size: 18),
                  label: const Text('Message Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _messageDoctor(BuildContext context) async {
    final a = appointment;
    try {
      final chatRepo = sl<ChatRepository>();
      final conv = await chatRepo.getOrCreateConversation(
        patientId: a.patientId,
        doctorId: a.doctorId,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      final isPatient = currentUserId == a.patientId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conv['id'] as String,
            currentUserId: currentUserId,
            contactName: isPatient ? a.doctorName : a.patientName,
            contactId: isPatient ? a.doctorId : a.patientId,
            contactAvatarUrl:
                isPatient ? a.avatarUrl : a.patientAvatarUrl,
            contactRole: isPatient ? 'doctor' : 'patient',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().contains('row-level security')
          ? 'You can only message a doctor you have an appointment with.'
          : 'Failed to start conversation.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _cancel(BuildContext context, String id) async {
    try {
      if (onCancel != null) {
        onCancel!(id);
      }
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  Color _statusColor(AppointmentStatus s) => switch (s) {
    AppointmentStatus.pending => AppColors.warning,
    AppointmentStatus.confirmed => AppColors.success,
    AppointmentStatus.completed => AppColors.info,
    AppointmentStatus.cancelled => AppColors.error,
    AppointmentStatus.rejected => AppColors.error,
  };

  Widget _section(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

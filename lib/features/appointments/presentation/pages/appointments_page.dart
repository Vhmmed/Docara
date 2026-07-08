import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_text.dart';
import '../../../../widgets/loading/loading_widgets.dart';
import '../../domain/entities/appointment_entity.dart';
import '../cubits/appointment_cubit.dart';
import '../widgets/appointment_detail_sheet.dart';
import '../widgets/book_appointment_sheet.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentCubit>()..loadAppointments(),
      child: const _AppointmentsBody(),
    );
  }
}

class _AppointmentsBody extends StatefulWidget {
  const _AppointmentsBody();

  @override
  State<_AppointmentsBody> createState() => _AppointmentsBodyState();
}

class _AppointmentsBodyState extends State<_AppointmentsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDetail(AppointmentEntity a) async {
    final cubit = context.read<AppointmentCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AppointmentDetailSheet(
        appointment: a,
        currentUserId: cubit.currentUserId,
        onCancel: (id) => cubit.cancelAppointment(id),
      ),
    );

    if (result == true && mounted) {
      cubit.loadAppointments();
    }
  }

  void _showBookingSheet() async {
    final cubit = context.read<AppointmentCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookAppointmentSheet(
        onBook: (doctorId, scheduledAt, type, notes) =>
            cubit.bookAppointment(
          doctorId: doctorId,
          scheduledAt: scheduledAt,
          type: type,
          notes: notes,
        ),
      ),
    );

    if (result == true && mounted) {
      cubit.loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70, right: 15),
        child: FloatingActionButton.extended(
          onPressed: _showBookingSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(CupertinoIcons.add, size: 20),
          label: const Text('Book Appointment'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) {
          final upcoming = state.upcoming;
          final past = state.past;
          final isLoading = state.isLoading;
          final error = state.error;

          return Column(
            children: [
              const Gap(70),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.only(right: 4, left: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.back,
                          size: 23,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Gap(15),
                    const CustomText(
                      text: 'My Appointments',
                      size: 24,
                      weight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      family: 'IBM Plex Sans',
                    ),
                  ],
                ),
              ),
              const Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Upcoming'),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${upcoming.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Tab(text: 'Past'),
                    ],
                  ),
                ),
              ),
              const Gap(20),
              Expanded(
                child: isLoading
                    ? const Center(child: AppRingSpinner())
                    : error != null
                        ? _buildErrorFallback(context)
                        : RefreshIndicator(
                            onRefresh: () => context
                                .read<AppointmentCubit>()
                                .loadAppointments(),
                            color: AppColors.primary,
                            backgroundColor: Colors.white,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildList(upcoming),
                                _buildList(past),
                              ],
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorFallback(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: AppColors.textSecondary.withAlpha(100),
        ),
        const SizedBox(height: 12),
        Text(
          'Could not load appointments',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () =>
              context.read<AppointmentCubit>().loadAppointments(),
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildList(List<AppointmentEntity> items) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 48,
                    color: AppColors.primary.withAlpha(75),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No appointments here yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appointment: items[i],
        onTap: () => _showDetail(items[i]),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withAlpha(40),
                  backgroundImage: a.avatarUrl != null && a.avatarUrl!.isNotEmpty
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
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.doctorName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.specialty,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${a.dateFormatted} at ${a.timeFormatted}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(a.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(a.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor(a.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus s) => switch (s) {
    AppointmentStatus.pending => AppColors.warning,
    AppointmentStatus.confirmed => AppColors.success,
    AppointmentStatus.completed => AppColors.info,
    AppointmentStatus.cancelled => AppColors.error,
    AppointmentStatus.rejected => AppColors.error,
  };

  String _statusLabel(AppointmentStatus s) => switch (s) {
    AppointmentStatus.pending => 'Pending',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.rejected => 'Rejected',
  };
}

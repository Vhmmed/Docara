import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medical_booking_app/core/constants/app_color.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/features/roles/domain/entities/doctor_dashboard_data.dart';
import 'package:medical_booking_app/features/roles/presentation/cubits/doctor_dashboard_cubit.dart';
import 'package:medical_booking_app/widgets/loading/loading_widgets.dart';
import 'package:medical_booking_app/features/roles/presentation/cubits/doctor_dashboard_state.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/appointment_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/headers/doctor_header.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/patient_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/headers/section_header.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/misc/specialty_badge.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/stat_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/schedule_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/tabs/doctor_patients_tab.dart';
import 'package:medical_booking_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_booking_app/features/notifications/presentation/cubits/notification_unread_count_cubit.dart';
import 'package:medical_booking_app/features/schedule/presentation/pages/schedule_page.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  late final DoctorDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<DoctorDashboardCubit>()..loadDashboard();
    _seedNotificationUnreadCount();
  }

  Future<void> _seedNotificationUnreadCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final count = await sl<NotificationRepository>().getUnreadCount(userId);
        sl<NotificationUnreadCountCubit>()..setCount(count)..init(userId);
        return;
      } catch (_) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
      bloc: _cubit,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: switch (state) {
              DoctorDashboardInitial() || DoctorDashboardLoading() =>
                const Center(child: AppDualToneRing()),
              DoctorDashboardError(message: final msg) =>
                Center(child: Text('Error: $msg')),
              DoctorDashboardLoaded(data: final data) =>
                _buildDashboard(data),
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboard(DoctorDashboardData data) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(10),
              DoctorHeader(userName: data.userName),
              const Gap(10),
              SpecialtyBadge(label: data.specialty),
            ],
          ),
        ),
        const Gap(20),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _cubit.loadDashboard(),
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: CupertinoIcons.person_2,
                          value: '${data.totalPatients}',
                          title: 'Total Patients',
                          change: '—',
                          isUp: true,
                          iconColor: const Color(0xff8FBAC7),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: StatCard(
                          icon: CupertinoIcons.calendar,
                          value: '${data.totalAppointments}',
                          title: 'Total Appointments',
                          change: '—',
                          isUp: true,
                          iconColor: const Color(0xff8FBAC7),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: StatCard(
                          icon: CupertinoIcons.money_dollar,
                          value: data.monthRevenue == 0
                              ? '\$0'
                              : '\$${data.monthRevenue.toStringAsFixed(0)}',
                          title: 'This Month',
                          change: '—',
                          isUp: true,
                          iconColor: const Color(0xff8FBAC7),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  SectionHeader(
                    title: 'My Schedule',
                    actionText: 'View & manage',
                    showChevron: true,
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SchedulePage(),
                        ),
                      ),
                    ),
                  const Gap(12),
                  ScheduleCard(dailyCounts: data.dailySchedule.map((s) => {
                    'date': s.date,
                    'count': s.count,
                    'isToday': s.isToday,
                  }).toList()),
                  const Gap(24),
                  SectionHeader(
                    title: "Today's Appointments",
                    actionText: 'View All',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SchedulePage(),
                        ),
                      ),
                    ),
                  const Gap(12),
                  if (data.todayAppointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No appointments today',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...data.todayAppointments.map((a) {
                      IconData icon;
                      String typeLabel;
                      switch (a.type) {
                        case 'video':
                          icon = CupertinoIcons.video_camera;
                          typeLabel = 'Video';
                          break;
                        case 'phone':
                          icon = CupertinoIcons.phone;
                          typeLabel = 'Phone';
                          break;
                        default:
                          icon = CupertinoIcons.person;
                          typeLabel = 'In-person';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppointmentCard(
                          title: a.patientName,
                          time: DateFormat('h:mm a').format(a.scheduledAt.toLocal()),
                          icon: icon,
                          typeLabel: typeLabel,
                        ),
                      );
                    }),
                  const Gap(20),
                  SectionHeader(
                    title: 'Recent Patients',
                    actionText: 'View All',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  const DoctorPatientsTab(),
                        ),
                      ),
                    ),
                  const Gap(12),
                  if (data.recentPatients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No recent patients',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...data.recentPatients.map((p) {
                      final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
                      final age = p.dateOfBirth != null
                          ? DateTime.now().year - p.dateOfBirth!.year
                          : null;
                      final ageGender = age != null ? '$age years' : '—';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PatientCard(
                          initial: initial,
                          name: p.name,
                          ageGender: ageGender,
                          lastVisitDate: p.lastVisit != null
                              ? DateFormat('MMM d').format(p.lastVisit!.toLocal())
                              : '—',
                          avatarUrl: p.avatarUrl,
                        ),
                      );
                    }),
                  const Gap(108),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/features/notifications/presentation/cubits/notification_unread_count_cubit.dart';
import 'package:medical_booking_app/features/notifications/presentation/pages/notification_page.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/stat_card.dart';
import 'package:medical_booking_app/widgets/loading/loading_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../misc/chart_widget.dart';

class AdminDashboardTab extends StatefulWidget {
  final void Function(int tabIndex, {int? subTab})? onNavigateToTab;
  const AdminDashboardTab({super.key, this.onNavigateToTab});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isLoading = true;

  int _totalUsers = 0;
  int _totalConsultations = 0;
  double _usersChange = 0;
  double _consultationsChange = 0;

  List<int> _chartData = [];
  List<String> _chartLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Month boundaries for change % computation
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);

      // --- Total Users (all profiles except admin) ---
      final allProfiles = await supabase
          .from('profiles')
          .select('id, created_at')
          .neq('role', 'admin');

      final totalUsers = allProfiles.length;

      int thisMonthUsers = 0;
      int lastMonthUsers = 0;
      for (final p in allProfiles) {
        final created = DateTime.tryParse(p['created_at'] as String? ?? '');
        if (created == null) continue;
        if (!created.isBefore(thisMonthStart)) {
          thisMonthUsers++;
        } else if (!created.isBefore(lastMonthStart) && created.isBefore(thisMonthStart)) {
          lastMonthUsers++;
        }
      }

      // --- Total Consultations ---
      final allAppointments = await supabase
          .from('appointments')
          .select('id, scheduled_at');

      final totalConsultations = allAppointments.length;

      int thisMonthAppts = 0;
      int lastMonthAppts = 0;
      for (final a in allAppointments) {
        final scheduled = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
        if (scheduled == null) continue;
        if (!scheduled.isBefore(thisMonthStart)) {
          thisMonthAppts++;
        } else if (!scheduled.isBefore(lastMonthStart) && scheduled.isBefore(thisMonthStart)) {
          lastMonthAppts++;
        }
      }

      // --- Chart: last 6 months grouped by month ---
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final monthlyCounts = <int, int>{};
      for (int i = 0; i < 6; i++) {
        final m = DateTime(now.year, now.month - 5 + i, 1);
        monthlyCounts[m.month] = 0;
      }

      for (final a in allAppointments) {
        final scheduled = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
        if (scheduled == null) continue;
        if (!scheduled.isBefore(sixMonthsAgo)) {
          monthlyCounts[scheduled.month] = (monthlyCounts[scheduled.month] ?? 0) + 1;
        }
      }

      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final chartData = <int>[];
      final chartLabels = <String>[];
      for (int i = 0; i < 6; i++) {
        final m = DateTime(now.year, now.month - 5 + i, 1);
        chartData.add(monthlyCounts[m.month] ?? 0);
        chartLabels.add(monthNames[m.month - 1]);
      }

      // Change percentages
      final usersChange = lastMonthUsers > 0
          ? ((thisMonthUsers - lastMonthUsers) / lastMonthUsers) * 100
          : (thisMonthUsers > 0 ? 100.0 : 0.0);

      final consultationsChange = lastMonthAppts > 0
          ? ((thisMonthAppts - lastMonthAppts) / lastMonthAppts) * 100
          : (thisMonthAppts > 0 ? 100.0 : 0.0);

      if (!mounted) return;
      setState(() {
        _totalUsers = totalUsers;
        _totalConsultations = totalConsultations;
        _usersChange = usersChange;
        _consultationsChange = consultationsChange;
        _chartData = chartData;
        _chartLabels = chartLabels;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('AdminDashboard _fetchStats error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  String _formatChangePercent(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(12),
        //   child: const SizedBox(height: 12,),
        // ),
        title:Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Overview',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(DateTime.now()),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BlocBuilder<NotificationUnreadCountCubit, int>(
                bloc: sl<NotificationUnreadCountCubit>(),
                builder: (_, count) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            CupertinoIcons.bell,
                            color: Color(0xff8FBAC7),
                            size: 24,
                          ),
                          if (count > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ) ,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppDualToneRing())
            : RefreshIndicator(
                onRefresh: _fetchStats,
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Gap( 16),

                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Users',
                            value: _formatNumber(_totalUsers),
                            change: _formatChangePercent(_usersChange),
                            icon: CupertinoIcons.person_2,
                            iconColor: AppColors.primary,
                            isUp: _usersChange >= 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Total Consultations',
                            value: _formatNumber(_totalConsultations),
                            change: _formatChangePercent(_consultationsChange),
                            icon: Icons.medical_services_outlined,
                            iconColor: AppColors.success,
                            isUp: _consultationsChange >= 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                title: 'Verify Doctors',
                                icon: Icons.verified_outlined,
                                color: AppColors.primary,
                                onTap: () => widget.onNavigateToTab?.call(1, subTab: 2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickActionCard(
                                title: 'User Management',
                                icon: Icons.manage_accounts_outlined,
                                color: AppColors.info,
                                onTap: () => widget.onNavigateToTab?.call(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                title: 'Analytics',
                                icon: Icons.analytics_outlined,
                                color: AppColors.warning,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming Soon')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickActionCard(
                                title: 'Settings',
                                icon: CupertinoIcons.settings,
                                color: AppColors.textSecondary,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming Soon')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Consultations Trend',
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.calendar,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Last 6 Months',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: _chartData.isEmpty
                                ? Center(
                                    child: Text(
                                      'No appointment data',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ChartWidget(
                                    data: _chartData,
                                    labels: _chartLabels,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 108),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

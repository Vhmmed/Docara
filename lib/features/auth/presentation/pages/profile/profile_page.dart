import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/shared/widgets/custom_snackbar_helper.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import '../../../data/datasources/profile_menu_data.dart';
import '../../../data/models/role_model.dart';
import '../../widgets/cards/profile_menu_card.dart';
import '../../widgets/cards/profile_info_card.dart';
import '../../../../notifications/presentation/pages/notification_page.dart';
import '../../../../roles/presentation/page/role_selection.dart';
import 'consultation_fee_page.dart';
import 'edit_profile_page.dart';
import 'help_center_page.dart';
import 'privacy_security_page.dart';
import 'terms_conditions_page.dart';
import 'working_hours_page.dart';
import '../../cubits/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  final String roleId;
  const ProfilePage({super.key, required this.roleId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late RoleModel currentRole;
  late ProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    currentRole = RoleModel.getRoleById(widget.roleId);
    _cubit = sl<ProfileCubit>();
    _cubit.fetchProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final fileSizeMB = File(picked.path).lengthSync() / 1048576;
      if (fileSizeMB > 5) {
        if (!mounted) return;
        CustomSnackBarHelper.show(
          context,
          message: 'Profile image must be under 5MB',
          isSuccess: false,
        );
        return;
      }

      _cubit.uploadAvatar(picked.path);
    } catch (e) {
      developer.log('Failed to pick image', name: 'ProfilePage', error: e);
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to pick image',
        isSuccess: false,
      );
    }
  }

  void _logout() {
    Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelection()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = currentRole.id == 'doctor';
    final bool isAdmin = currentRole.id == 'admin';
    final accountItems = ProfileMenuData.accountItems;
    final supportItems = ProfileMenuData.supportItems;
    final professionalItems = ProfileMenuData.professionalItems;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          bloc: _cubit,
          builder: (context, state) {
            final userName = switch (state) {
              ProfileLoaded(:final profile) => profile.fullName,
              _ => null,
            };
            final avatarUrl = switch (state) {
              ProfileLoaded(:final profile) => profile.avatarUrl,
              _ => null,
            };
            final isUploading = state is ProfileUploading;
            final profile = switch (state) {
              ProfileLoaded(:final profile) => profile,
              _ => null,
            };

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 60,
                  collapsedHeight: 60,
                  toolbarHeight: 0,
                  primary: false,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.grey.shade50,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const SizedBox(width: 28),
                        const Spacer(),
                        const CustomText(
                          text: 'Settings',
                          size: 24,
                          color: Colors.black,
                          weight: FontWeight.w700,
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.settings,
                          size: 28,
                          color: Color(0xff8FBAC7),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(30),

                        ProfileInfoCard(
                          userName: userName,
                          avatarUrl: avatarUrl,
                          isUploading: isUploading,
                          roleId: widget.roleId,
                          currentRole: currentRole,
                          onPickImage: _pickProfileImage,
                          specialtyName: profile?.specialtyName,
                          clinicAddress: profile?.clinicAddress,
                          isVerified: profile?.isVerified,
                          verificationStatus: profile?.verificationStatus,
                        ),
                        const Gap(30),

                        // Account Section
                        const CustomText(
                          text: 'Account',
                          size: 16,
                          color: Colors.grey,
                          weight: FontWeight.w700,
                        ),
                        const Gap(16),
                        ProfileMenuCard(
                          items: accountItems.map((item) {
                            final title = item['title'] as String;
                            return ProfileMenuItem(
                              title: title,
                              iconPath: item['icon'] as String,
                              onTap: () {
                                if (title == 'Notifications') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationPage(),
                                    ),
                                  );
                                } else if (title == 'Edit Profile') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfilePage(
                                        roleId: widget.roleId,
                                      ),
                                    ),
                                  );
                                } else if (title == 'Privacy & Security') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrivacySecurityPage(),
                                    ),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(30),

                        // Professional Section (doctor only)
                        if (isDoctor) ...[
                          const CustomText(
                            text: 'Professional',
                            size: 16,
                            color: Colors.grey,
                            weight: FontWeight.w700,
                          ),
                          const Gap(16),
                          ProfileMenuCard(
                            items: professionalItems.map((item) {
                              final title = item['title'] as String;
                              Widget page;
                              if (title == 'Working Hours') {
                                page = const WorkingHoursPage();
                              } else {
                                page = ConsultationFeePage(
                                  currentFee: profile?.consultationFee,
                                );
                              }
                              return ProfileMenuItem(
                                title: title,
                                iconPath: item['icon'] as String,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => page),
                                ),
                              );
                            }).toList(),
                          ),
                          const Gap(30),
                        ],

                        // Admin Section
                        if (isAdmin) ...[
                          const CustomText(
                            text: 'Admin',
                            size: 16,
                            color: Colors.grey,
                            weight: FontWeight.w700,
                          ),
                          const Gap(16),
                          _SystemOverviewCard(),
                          const Gap(30),
                        ],

                        // Support Section
                        const CustomText(
                          text: 'Support',
                          size: 16,
                          color: Colors.grey,
                          weight: FontWeight.w700,
                        ),
                        const Gap(16),
                        ProfileMenuCard(
                          items: supportItems.map((item) {
                            final title = item['title'] as String;
                            Widget page;
                            if (title == 'Help Center') {
                              page = const HelpCenterPage();
                            } else {
                              page = const TermsConditionsPage();
                            }
                            return ProfileMenuItem(
                              title: title,
                              iconPath: item['icon'] as String,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => page),
                              ),
                            );
                          }).toList(),
                        ),
                        const Gap(30),

                        // Logout
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.red.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.square_arrow_right,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                Gap(10),
                                CustomText(
                                  text: 'Logout',
                                  size: 16,
                                  color: Colors.red,
                                  weight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SystemOverviewCard extends StatefulWidget {
  @override
  State<_SystemOverviewCard> createState() => _SystemOverviewCardState();
}

class _SystemOverviewCardState extends State<_SystemOverviewCard> {
  Future<Map<String, int>> _fetchStats() async {
    final supabase = Supabase.instance.client;
    final results = await Future.wait([
      supabase.from('profiles').select('id'),
      supabase.from('doctors').select('id'),
      supabase.from('doctors').select('id').eq('status', 'pending'),
      supabase.from('appointments').select('id'),
    ]);
    final counts = results.map((r) => (r as List).length).toList();
    return {
      'total_users': counts[0],
      'total_doctors': counts[1],
      'pending_doctors': counts[2],
      'total_appointments': counts[3],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xff8FBAC7).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
            future: _fetchStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AppRingSpinner(size: 28),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Unable to load system stats.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                );
              }
              final stats = snapshot.data!;
              return _StatGrid(stats: stats);
            },
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Map<String, int> stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatItem(
              icon: CupertinoIcons.person_3_fill,
              label: 'Total Users',
              count: stats['total_users'] ?? 0,
              color: AppColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatItem(
              icon: CupertinoIcons.heart,
              label: 'Total Doctors',
              count: stats['total_doctors'] ?? 0,
              color: AppColors.info,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatItem(
              icon: CupertinoIcons.clock,
              label: 'Pending Verifications',
              count: stats['pending_doctors'] ?? 0,
              color: AppColors.warning,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatItem(
              icon: CupertinoIcons.calendar,
              label: 'Total Appointments',
              count: stats['total_appointments'] ?? 0,
              color: AppColors.success,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

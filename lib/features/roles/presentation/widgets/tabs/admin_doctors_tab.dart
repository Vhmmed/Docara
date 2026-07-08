import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../cards/doctor_card.dart';
import '../sheets/doctor_detail_sheet.dart';
import '../cards/doctor_verification_card.dart';

class AdminDoctorsTab extends StatefulWidget {
  final int? navigateToSubTab;
  const AdminDoctorsTab({super.key, this.navigateToSubTab});

  @override
  State<AdminDoctorsTab> createState() => _AdminDoctorsTabState();
}

class _AdminDoctorsTabState extends State<AdminDoctorsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<Map<String, dynamic>> _pendingDoctors = [];
  bool _isLoadingPending = false;
  List<Map<String, dynamic>> _approvedDoctors = [];
  bool _isLoadingApproved = false;
  List<Map<String, dynamic>> _patients = [];
  bool _isLoadingPatients = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.navigateToSubTab ?? 0,
    );
    _fetchPendingDoctors();
    _fetchApprovedDoctors();
    _fetchPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingDoctors() async {
    setState(() => _isLoadingPending = true);
    try {
      final supabase = Supabase.instance.client;

      final pending = await supabase
          .from('doctors')
          .select('id, years_of_experience, clinic_address, specialty_id, bio, consultation_fee, avatar_url, license_path, certificate_path')
          .eq('status', 'pending');

      if (!mounted) return;

      final doctorIds = pending
          .map((d) => d['id'] as String)
          .toList();

      if (doctorIds.isEmpty) {
        setState(() {
          _pendingDoctors = [];
          _isLoadingPending = false;
        });
        return;
      }

      final allProfiles = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url');

      final allSpecialties = await supabase
          .from('specialties')
          .select('id, name');

      final idSet = doctorIds.toSet();
      final profileMap = <String, String>{};
      final profileAvatarUrlMap = <String, String?>{};
      for (final p in allProfiles) {
        final id = p['id'] as String;
        if (idSet.contains(id)) {
          profileMap[id] = p['full_name'] as String? ?? 'Unknown Doctor';
          profileAvatarUrlMap[id] = p['avatar_url'] as String?;
        }
      }

      final specialtyMap = <String, String>{};
      for (final s in allSpecialties) {
        specialtyMap[s['id'] as String] = s['name'] as String;
      }

      final merged = pending.map((doc) {
        final id = doc['id'] as String;
        final specialtyId = doc['specialty_id'] as String? ?? '';
        return <String, dynamic>{
          'id': id,
          'name': profileMap[id] ?? 'Unknown Doctor',
          'specialty': specialtyMap[specialtyId] ?? 'Unknown',
          'experience': '${doc['years_of_experience'] ?? 0} years',
          'location': doc['clinic_address'] as String? ?? '',
          'bio': doc['bio'] as String? ?? '',
          'fee': doc['consultation_fee']?.toString() ?? '—',
          'avatar_url': doc['avatar_url'] as String? ?? '',
          'profile_avatar_url': profileAvatarUrlMap[id],
          'license_path': doc['license_path'] as String? ?? '',
          'certificate_path': doc['certificate_path'] as String? ?? '',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _pendingDoctors = merged;
        _isLoadingPending = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending doctors: $e');
      if (!mounted) return;
      setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _fetchApprovedDoctors() async {
    setState(() => _isLoadingApproved = true);
    try {
      final supabase = Supabase.instance.client;

      final approved = await supabase
          .from('doctors')
          .select('id, years_of_experience, consultation_fee, specialty_id, avatar_url')
          .eq('status', 'approved');

      if (!mounted) return;

      final doctorIds = approved
          .map((d) => d['id'] as String)
          .toList();

      if (doctorIds.isEmpty) {
        setState(() {
          _approvedDoctors = [];
          _isLoadingApproved = false;
        });
        return;
      }

      final allProfiles = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url');

      final allSpecialties = await supabase
          .from('specialties')
          .select('id, name');

      final idSet = doctorIds.toSet();
      final profileMap = <String, String>{};
      final profileAvatarUrlMap = <String, String?>{};
      for (final p in allProfiles) {
        final id = p['id'] as String;
        if (idSet.contains(id)) {
          profileMap[id] = p['full_name'] as String? ?? 'Unknown Doctor';
          profileAvatarUrlMap[id] = p['avatar_url'] as String?;
        }
      }

      final specialtyMap = <String, String>{};
      for (final s in allSpecialties) {
        specialtyMap[s['id'] as String] = s['name'] as String;
      }

      final merged = approved.map((doc) {
        final id = doc['id'] as String;
        final specialtyId = doc['specialty_id'] as String? ?? '';
        return <String, dynamic>{
          'id': id,
          'name': profileMap[id] ?? 'Unknown Doctor',
          'specialty': specialtyMap[specialtyId] ?? 'Unknown',
          'experience': '${doc['years_of_experience'] ?? 0}',
          'fee': doc['consultation_fee']?.toString() ?? '0',
          'avatar_url': doc['avatar_url'] as String?,
          'profile_avatar_url': profileAvatarUrlMap[id],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _approvedDoctors = merged;
        _isLoadingApproved = false;
      });
    } catch (e) {
      debugPrint('Error fetching approved doctors: $e');
      if (!mounted) return;
      setState(() => _isLoadingApproved = false);
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final supabase = Supabase.instance.client;

      final allProfiles = await supabase
          .from('profiles')
          .select('id, full_name, created_at, avatar_url, role')
          .neq('role', 'admin');

      final allDoctorIds = await supabase
          .from('doctors')
          .select('id');

      final doctorIdSet = allDoctorIds
          .map((d) => d['id'] as String)
          .toSet();

      final patientProfiles = allProfiles
          .where((p) => !doctorIdSet.contains(p['id'] as String))
          .toList();

      // Fetch all appointments and count per patient in one query
      final allAppointments = await supabase
          .from('appointments')
          .select('patient_id');

      final consultationCounts = <String, int>{};
      for (final a in allAppointments) {
        final pid = a['patient_id'] as String;
        consultationCounts[pid] = (consultationCounts[pid] ?? 0) + 1;
      }

      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];

      final merged = patientProfiles.map((p) {
        final id = p['id'] as String;
        final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '');
        final joined = createdAt != null
            ? '${monthNames[createdAt.month - 1]} ${createdAt.year}'
            : '—';

        return <String, dynamic>{
          'name': p['full_name'] as String? ?? 'Unknown',
          'email': '—',
          'joined': joined,
          'consultations': '${consultationCounts[id] ?? 0}',
          'avatar_url': p['avatar_url'] as String?,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _patients = merged;
        _isLoadingPatients = false;
      });
    } catch (e) {
      developer.log('AdminDoctorsTab _fetchPatients error: $e');
      if (!mounted) return;
      setState(() => _isLoadingPatients = false);
    }
  }

  void _showDoctorDetailSheet(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DoctorDetailSheet(
        name: doctor['name'] as String,
        specialty: doctor['specialty'] as String,
        experience: doctor['experience'] as String,
        location: doctor['location'] as String,
        bio: doctor['bio'] as String,
        fee: doctor['fee'] as String,
        avatarUrl: doctor['avatar_url'] as String,
        profilesAvatarUrl: doctor['profile_avatar_url'] as String?,
        licensePath: doctor['license_path'] as String,
        certificatePath: doctor['certificate_path'] as String,
        onApprove: () {
          Navigator.pop(context);
          _approveDoctor(doctor['id'] as String);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectDoctor(doctor['id'] as String);
        },
      ),
    );
  }

  Future<void> _approveDoctor(String doctorId) async {
    try {
      await Supabase.instance.client
          .from('doctors')
          .update({'status': 'approved'})
          .eq('id', doctorId);

      if (!mounted) return;
      setState(() {
        _pendingDoctors.removeWhere((d) => d['id'] == doctorId);
      });
    } catch (e) {
      debugPrint('Error approving doctor: $e');
    }
  }

  Future<void> _rejectDoctor(String doctorId) async {
    try {
      await Supabase.instance.client
          .from('doctors')
          .update({'status': 'rejected'})
          .eq('id', doctorId);

      if (!mounted) return;
      setState(() {
        _pendingDoctors.removeWhere((d) => d['id'] == doctorId);
      });
    } catch (e) {
      debugPrint('Error rejecting doctor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'User Management',
                    color: AppColors.textPrimary,
                    weight: FontWeight.bold,
                    size: 25,
                  ),
                  const Gap(3),
                  CustomText(
                    text: 'Search and manage users',
                    color: AppColors.textSecondary,
                  ),
                  const Gap(20),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child:TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  const Gap(10),
                  Container(
                    height: 40,
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                      ),
                      tabs: [
                        const Tab(text: 'Patients'),
                        const Tab(text: 'Doctors'),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Pending'),
                              if (_pendingDoctors.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_pendingDoctors.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(15),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 108),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPatientsList(),
                    _buildDoctorsList(),
                    _buildVerificationList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    if (_isLoadingPatients) {
      return const Center(child: AppRingSpinner());
    }

    if (_patients.isEmpty) {
      return Center(
        child: Text(
          'No patients found',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final filtered = _patients.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final email = (p['email'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final patient = filtered[index];
        return DoctorCard(
          name: patient['name'] as String,
          subtitle: patient['email'] as String,
          info1: 'Joined: ${patient['joined']}',
          info2: 'Consultations: ${patient['consultations']}',
          avatarUrl: patient['avatar_url'] as String?,
          isDoctor: false,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildDoctorsList() {
    if (_isLoadingApproved) {
      return const Center(child: AppRingSpinner());
    }

    if (_approvedDoctors.isEmpty) {
      return Center(
        child: Text(
          'No approved doctors',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final filtered = _approvedDoctors.where((d) {
      final name = (d['name'] as String).toLowerCase();
      final specialty = (d['specialty'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchApprovedDoctors,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final doctor = filtered[index];
          final docAvatar = (doctor['profile_avatar_url'] as String?)?.isNotEmpty == true
              ? doctor['profile_avatar_url'] as String
              : (doctor['avatar_url'] as String?) ?? '';
          return DoctorCard(
            name: doctor['name'] as String,
            subtitle: doctor['specialty'] as String,
            info1: 'Experience: ${doctor['experience']} years',
            info2: 'Fee: \$${doctor['fee']}',
            avatarUrl: docAvatar.isNotEmpty ? docAvatar : null,
            isDoctor: true,
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildVerificationList() {
    if (_isLoadingPending) {
      return const Center(child: AppRingSpinner());
    }

    if (_pendingDoctors.isEmpty) {
      return Center(
        child: Text(
          'No pending doctors',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingDoctors,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _pendingDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _pendingDoctors[index];
          final doctorId = doctor['id'] as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DoctorVerificationCard(
              name: doctor['name'] as String,
              specialty: doctor['specialty'] as String,
              experience: doctor['experience'] as String,
              location: doctor['location'] as String,
              avatarUrl: doctor['avatar_url'] as String?,
              documents: const [
                'Medical License',
                'Board Certification',
                'ID Verification',
                'Background Check',
              ],
              onApprove: () => _approveDoctor(doctorId),
              onReject: () => _rejectDoctor(doctorId),
              onViewDetails: () => _showDoctorDetailSheet(doctor),
            ),
          );
        },
      ),
    );
  }
}

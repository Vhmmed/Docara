import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/features/appointments/data/appointment_service.dart';
import 'package:medical_booking_app/features/appointments/presentation/pages/appointments_page.dart';
import 'package:medical_booking_app/features/appointments/presentation/widgets/book_appointment_sheet.dart';
import 'package:medical_booking_app/widgets/loading/loading_widgets.dart';
import 'package:medical_booking_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:medical_booking_app/features/chat/presentation/widgets/chat_detail_page.dart';
import 'package:medical_booking_app/features/medical_records/presentation/pages/patient_records_page.dart';
import 'package:medical_booking_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_booking_app/features/notifications/presentation/cubits/notification_unread_count_cubit.dart';
import 'package:medical_booking_app/features/roles/domain/entities/patient_home_data.dart';
import 'package:medical_booking_app/features/roles/presentation/cubits/patient_home_cubit.dart';
import 'package:medical_booking_app/features/roles/presentation/cubits/patient_home_state.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/doctor_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/health_tip_card.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/headers/patient_header.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/sheets/quick_actions_row.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/cards/upcoming_appointment_card.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class PatientScreen extends StatefulWidget {
  final String roleId;
  const PatientScreen({super.key, required this.roleId});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final TextEditingController searchController = TextEditingController();
  late final PatientHomeCubit _cubit;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cubit = sl<PatientHomeCubit>()..loadHome();
    searchController.addListener(_onSearchChanged);
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

  void _onSearchChanged() {
    setState(() => _searchQuery = searchController.text);
  }

  List<DoctorInfo> _filteredDoctors(List<DoctorInfo> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    final query = _searchQuery.toLowerCase();
    return doctors.where((doc) {
      return doc.name.toLowerCase().contains(query) ||
          doc.specialty.toLowerCase().contains(query);
    }).toList();
  }

  String _formatAppointmentDate(DateTime dt) {
    return '${DateFormat('MMMM d, yyyy').format(dt.toLocal())} \u2022 ${DateFormat('h:mm a').format(dt.toLocal())}';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  Future<void> _bookAppointment(
    String doctorId,
    DateTime scheduledAt,
    String type,
    String? notes,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final fee = await _fetchDoctorFee(doctorId);
      await AppointmentService.bookAppointment(
        patientId: userId,
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        type: type,
        notes: notes,
        fee: fee,
      );
    } catch (_) {}
  }

  Future<double> _fetchDoctorFee(String doctorId) async {
    final doctor = await Supabase.instance.client
        .from('doctors')
        .select('consultation_fee')
        .eq('id', doctorId)
        .single();
    return (doctor['consultation_fee'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _messageDoctor(
    BuildContext context,
    String doctorId,
    String doctorName,
    String? doctorAvatarUrl,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final chatRepo = sl<ChatRepository>();
      final conv = await chatRepo.getOrCreateConversation(
        patientId: userId,
        doctorId: doctorId,
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conv['id'] as String,
            currentUserId: userId,
            contactName: doctorName,
            contactId: doctorId,
            contactAvatarUrl: doctorAvatarUrl,
            contactRole: 'doctor',
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

  @override
  void dispose() {
    _cubit.close();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: BlocBuilder<PatientHomeCubit, PatientHomeState>(
          bloc: _cubit,
          builder: (context, state) {
            final data = switch (state) {
              PatientHomeLoaded(data: final d) => d,
              _ => null,
            };

            return RefreshIndicator(
              onRefresh: () => _cubit.loadHome(),
              color: AppColors.primary,
              backgroundColor: Colors.white,
              strokeWidth: 2,
              displacement: 60,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 230,
                    collapsedHeight: 230,
                    toolbarHeight: 0,
                    primary: false,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    flexibleSpace: PatientHeader(
                      userName: data?.userName,
                      roleId: widget.roleId,
                      searchController: searchController,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const Gap(30),
                          switch (state) {
                            PatientHomeLoading() =>
                              const Center(child: AppRingSpinner()),
                            PatientHomeError() => const SizedBox.shrink(),
                            PatientHomeLoaded(data: final d) => Column(
                              children: [
                                const Row(
                                  children: [
                                    CustomText(
                                      text: 'Upcoming Appointment',
                                      size: 18,
                                      color: Colors.black,
                                      weight: FontWeight.w700,
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                _buildUpcomingSection(
                                    d.upcomingAppointment),
                              ],
                            ),
                            _ => const SizedBox.shrink(),
                          },
                          const Gap(25),
                          const Row(
                            children: [
                              CustomText(
                                text: 'Find a Doctor',
                                size: 20,
                                color: Colors.black,
                                weight: FontWeight.w700,
                              ),
                            ],
                          ),
                          switch (state) {
                            PatientHomeLoading() => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: AppRingSpinner(),
                                ),
                              ),
                            PatientHomeError() => const SizedBox.shrink(),
                            PatientHomeLoaded(data: final d) =>
                              _buildDoctorList(d.doctors),
                            _ => const SizedBox.shrink(),
                          },
                          const Row(
                            children: [
                              CustomText(
                                text: 'Quick Actions',
                                size: 20,
                                color: Colors.black,
                                weight: FontWeight.w700,
                              ),
                            ],
                          ),
                          const Gap(10),
                          QuickActionsRow(
                            onBookAppointment: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AppointmentsPage()),
                            ),
                            onMedicalRecords: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PatientRecordsPage(),
                                ),
                              );
                            },
                          ),
                          const Gap(25),
                          const HealthTipCard(),
                          const SizedBox(height: 108),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(UpcomingAppointmentData? upcoming) {
    if (upcoming == null) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No upcoming appointments',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return UpcomingAppointmentCard(
      doctorName: upcoming.doctorName,
      specialty: upcoming.specialty,
      date: _formatAppointmentDate(upcoming.scheduledAt),
      showTodayBadge: _isToday(upcoming.scheduledAt),
      doctorAvatarUrl: upcoming.doctorAvatarUrl,
    );
  }

  Widget _buildDoctorList(List<DoctorInfo> doctors) {
    final filtered = _filteredDoctors(doctors);
    if (doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(
            'No doctors available yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(
            'No doctors match your search',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length > 10 ? 10 : filtered.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (context, index) {
        final doc = filtered[index];
        return DoctorCard(
          name: doc.name,
          subtitle: doc.specialty,
          info1: doc.consultationFee != null
              ? 'Fee: \$${doc.consultationFee!.toStringAsFixed(0)}'
              : '',
          info2: doc.clinicAddress ?? '',
          avatarUrl: doc.avatarUrl,
          isDoctor: true,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => BookAppointmentSheet(
                onBook: _bookAppointment,
              ),
            );
          },
          onMessageTap: () =>
              _messageDoctor(context, doc.id, doc.name, doc.avatarUrl),
        );
      },
    );
  }
}

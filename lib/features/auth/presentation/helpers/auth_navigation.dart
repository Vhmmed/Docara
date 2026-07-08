import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/doctor_onboarding/complete_doctor_profile_page.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/doctor_onboarding/doctor_waiting_approval_page.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/profile/profile_page.dart';
import 'package:medical_booking_app/features/roles/presentation/page/doctor_screen.dart';
import 'package:medical_booking_app/features/roles/presentation/page/patient_screen.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/tabs/admin_appointments_tab.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/tabs/admin_dashboard_tab.dart';
import 'package:medical_booking_app/features/roles/presentation/widgets/tabs/admin_doctors_tab.dart';
import 'package:medical_booking_app/features/chat/presentation/pages/messages_page.dart';
import 'package:medical_booking_app/shared/widgets/glass_nav_shell.dart';

/// Determines the correct screen for a doctor based on their approval status.
///
/// - `approved` → [DoctorScreen]
/// - `pending` with existing `doctors` row → [DoctorWaitingApprovalPage]
/// - `pending` without `doctors` row → [CompleteDoctorProfilePage] (resume onboarding)
/// - any other role → returns null (caller should handle non-doctor routing)
Future<Widget?> resolveDoctorScreen({
  required String userId,
  required String status,
}) async {
  if (status == 'approved') {
    return const DoctorScreen();
  }

  // pending (or unknown status) — check if doctor has submitted profile
  try {
    final result = await Supabase.instance.client
        .from('doctors')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (result != null) {
      return const DoctorWaitingApprovalPage();
    }

    // No doctors row yet — resume onboarding; read specialty from user metadata
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final specialtyId = metadata?['specialty_id'] as String?;
    return CompleteDoctorProfilePage(
      userId: userId,
      specialtyId: specialtyId,
    );
  } catch (_) {
    return const DoctorWaitingApprovalPage();
  }
}

/// Shared navigation for any role.
/// For doctors, wraps approved doctors in [GlassNavShell].
/// Non-approved doctors show waiting/onboarding screen directly.
/// Other roles get role-specific [GlassNavShell] with appropriate tabs.
Future<void> navigateToRoleScreen({
  required BuildContext context,
  required String role,
  required String status,
  required String userId,
  String? patientRoleId,
}) async {
  Widget screen;

  if (role == 'doctor') {
    if (status == 'approved') {
      screen = GlassNavShell(
        items: _doctorNavItems(),
        messagesTabIndex: 1,
      );
    } else {
      final doctorScreen = await resolveDoctorScreen(
        userId: userId,
        status: status,
      );
      if (doctorScreen == null) return;
      screen = doctorScreen;
    }
  } else if (role == 'admin') {
    screen = GlassNavShell(items: _adminNavItems());
  } else {
    screen = GlassNavShell(
      items: _patientNavItems(patientRoleId ?? 'patient'),
      messagesTabIndex: 1,
    );
  }

  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}

// ---------------------------------------------------------------------------
// Per-role tab configuration
// ---------------------------------------------------------------------------

List<GlassNavItem> _patientNavItems(String roleId) => [
  GlassNavItem(
    icon: Icons.home_filled,
    label: 'Home',
    screen: PatientScreen(roleId: roleId),
  ),
  GlassNavItem(
    icon: CupertinoIcons.chat_bubble_2,
    label: 'Messages',
    screen: MessagesPage(roleId: roleId),
  ),
  GlassNavItem(
    icon: CupertinoIcons.person,
    label: 'Profile',
    screen: ProfilePage(roleId: roleId),
  ),
];

List<GlassNavItem> _doctorNavItems() => [
  const GlassNavItem(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    screen: DoctorScreen(),
  ),
  GlassNavItem(
    icon: CupertinoIcons.chat_bubble_2,
    label: 'Messages',
    screen: MessagesPage(roleId: 'doctor'),
  ),
  const GlassNavItem(
    icon: CupertinoIcons.person,
    label: 'Profile',
    screen: ProfilePage(roleId: 'doctor'),
  ),
];

List<GlassNavItem> _adminNavItems() => [
  const GlassNavItem(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    screen: AdminDashboardTab(),
  ),
  const GlassNavItem(
    icon: CupertinoIcons.person_2,
    label: 'Doctors',
    screen: AdminDoctorsTab(),
  ),
  const GlassNavItem(
    icon: CupertinoIcons.calendar,
    label: 'Appointments',
    screen: AdminAppointmentsTab(),
  ),
  GlassNavItem(
    icon: CupertinoIcons.person,
    label: 'Profile',
    screen: const ProfilePage(roleId: 'admin'),
  ),
];

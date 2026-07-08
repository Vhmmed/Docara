import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/profile/profile_page.dart';
import '../widgets/tabs/admin_appointments_tab.dart';
import '../widgets/tabs/admin_dashboard_tab.dart';
import '../widgets/tabs/admin_doctors_tab.dart';
import '../widgets/nav/admin_nav_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  int? _navigateToSubTab;

  static const _navLabels = ['Dashboard', 'Doctors', 'Appointments', 'Profile'];

  static const _outlinedIcons = [
    Icons.dashboard_outlined,
    CupertinoIcons.person_2,
    CupertinoIcons.calendar,
    CupertinoIcons.person,
  ];

  static const _filledIcons = [
    Icons.dashboard,
    CupertinoIcons.person_2,
    CupertinoIcons.calendar,
    CupertinoIcons.person,
  ];

  void _onNavigateToTab(int index, {int? subTab}) {
    setState(() {
      _currentIndex = index;
      _navigateToSubTab = subTab;
    });
  }

  List<Widget> get _pages => [
    AdminDashboardTab(
      onNavigateToTab: _onNavigateToTab,
    ),
    AdminDoctorsTab(navigateToSubTab: _navigateToSubTab),
    const AdminAppointmentsTab(),
    const ProfilePage(roleId: 'admin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _pages[_currentIndex],
      bottomNavigationBar: AdminNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _currentIndex = i;
          _navigateToSubTab = null;
        }),
        labels: _navLabels,
        outlinedIcons: _outlinedIcons,
        filledIcons: _filledIcons,
      ),
    );
  }
}
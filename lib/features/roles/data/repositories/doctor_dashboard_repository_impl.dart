import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../appointments/data/appointment_service.dart';
import '../../../appointments/data/doctor_stats_service.dart';
import '../../domain/entities/doctor_dashboard_data.dart';
import '../../domain/repositories/doctor_dashboard_repository.dart';

class DoctorDashboardRepositoryImpl implements DoctorDashboardRepository {
  DoctorDashboardRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<DoctorDashboardData> getDashboard(String doctorId) async {
    final results = await Future.wait([
      _fetchUserName(doctorId),
      DoctorStatsService.getDoctorStats(doctorId),
      AppointmentService.getDoctorPatients(doctorId),
      AppointmentService.getDoctorTodayAppointments(doctorId),
      AppointmentService.getDoctorDailySchedule(doctorId),
      AppointmentService.getDoctorSpecialtyName(doctorId),
    ]);

    final userName = results[0] as String?;
    final stats = results[1] as DoctorStats;
    final patients = (results[2] as List).cast<Map<String, dynamic>>();

    final recentPatients = patients.take(5).map((p) {
      return RecentPatient(
        id: p['id'] as String? ?? '',
        name: p['name'] as String? ?? 'Unknown',
        lastVisit: p['lastVisit'] as DateTime?,
        dateOfBirth: p['dateOfBirth'] as DateTime?,
        avatarUrl: p['avatarUrl'] as String?,
        appointmentCount: p['appointmentCount'] as int? ?? 0,
      );
    }).toList();

    final todayApps = (results[3] as List).cast<Map<String, dynamic>>();
    final todayAppointments = todayApps.map((a) {
      return TodayAppointment(
        patientName: a['patientName'] as String? ?? 'Unknown',
        patientAvatarUrl: a['patientAvatarUrl'] as String?,
        scheduledAt: a['scheduledAt'] as DateTime,
        status: a['status'] as String? ?? 'pending',
        type: a['type'] as String? ?? 'in_person',
      );
    }).toList();

    final schedule = (results[4] as List).cast<Map<String, dynamic>>();
    final dailySchedule = schedule.map((s) {
      return DaySchedule(
        date: s['date'] as DateTime,
        count: s['count'] as int? ?? 0,
        isToday: s['isToday'] as bool? ?? false,
      );
    }).toList();

    return DoctorDashboardData(
      userName: userName,
      totalPatients: stats.totalPatients,
      totalAppointments: stats.totalAppointments,
      monthRevenue: stats.monthRevenue,
      recentPatients: recentPatients,
      todayAppointments: todayAppointments,
      dailySchedule: dailySchedule,
      specialty: results[5] as String? ?? 'General',
    );
  }

  Future<String?> _fetchUserName(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      return response['full_name'] as String?;
    } catch (e) {
      developer.log('_fetchUserName error: $e');
      return null;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorStats {
  final int totalPatients;
  final int totalAppointments;
  final double monthRevenue;

  const DoctorStats({
    required this.totalPatients,
    required this.totalAppointments,
    required this.monthRevenue,
  });

  String get monthRevenueFormatted {
    if (monthRevenue == 0) return '\$0';
    if (monthRevenue >= 1000) {
      return '\$${monthRevenue.toStringAsFixed(0)}';
    }
    return '\$${monthRevenue.toStringAsFixed(2)}';
  }
}

class DoctorStatsService {
  DoctorStatsService._();

  static Future<DoctorStats> getDoctorStats(String doctorId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final rows = await Supabase.instance.client
        .from('appointments')
        .select('patient_id, fee, status, scheduled_at')
        .eq('doctor_id', doctorId);

    final list = (rows as List).cast<Map<String, dynamic>>();

    // Filter to this-month appointments
    final monthRows = list.where((r) {
      final d = DateTime.parse(r['scheduled_at'] as String);
      return !d.isBefore(monthStart) && !d.isAfter(monthEnd);
    }).toList();

    // Distinct patients this month
    final patientIds = monthRows.map((r) => r['patient_id'] as String).toSet();
    final totalPatients = patientIds.length;

    // Total appointments this month
    final totalAppointments = monthRows.length;

    // This month revenue: completed appointments only
    double monthRevenue = 0;
    for (final r in monthRows) {
      final status = r['status'] as String?;
      if (status != 'completed') continue;
      monthRevenue += (r['fee'] as num?)?.toDouble() ?? 0;
    }

    return DoctorStats(
      totalPatients: totalPatients,
      totalAppointments: totalAppointments,
      monthRevenue: monthRevenue,
    );
  }
}

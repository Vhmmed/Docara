class DoctorDashboardData {
  final String? userName;
  final int totalPatients;
  final int totalAppointments;
  final double monthRevenue;
  final List<RecentPatient> recentPatients;
  final List<TodayAppointment> todayAppointments;
  final List<DaySchedule> dailySchedule;
  final String specialty;

  const DoctorDashboardData({
    this.userName,
    this.totalPatients = 0,
    this.totalAppointments = 0,
    this.monthRevenue = 0,
    this.recentPatients = const [],
    this.todayAppointments = const [],
    this.dailySchedule = const [],
    this.specialty = 'General',
  });
}

class RecentPatient {
  final String id;
  final String name;
  final DateTime? lastVisit;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final int appointmentCount;

  const RecentPatient({
    required this.id,
    required this.name,
    this.lastVisit,
    this.dateOfBirth,
    this.avatarUrl,
    this.appointmentCount = 0,
  });
}

class TodayAppointment {
  final String patientName;
  final String? patientAvatarUrl;
  final DateTime scheduledAt;
  final String status;
  final String type;

  const TodayAppointment({
    required this.patientName,
    this.patientAvatarUrl,
    required this.scheduledAt,
    this.status = 'pending',
    this.type = 'in_person',
  });
}

class DaySchedule {
  final DateTime date;
  final int count;
  final bool isToday;

  const DaySchedule({
    required this.date,
    this.count = 0,
    this.isToday = false,
  });
}

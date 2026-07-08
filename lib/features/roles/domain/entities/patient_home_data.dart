class PatientHomeData {
  final String? userName;
  final UpcomingAppointmentData? upcomingAppointment;
  final List<DoctorInfo> doctors;

  const PatientHomeData({
    this.userName,
    this.upcomingAppointment,
    this.doctors = const [],
  });
}

class UpcomingAppointmentData {
  final String doctorName;
  final String? doctorAvatarUrl;
  final String specialty;
  final DateTime scheduledAt;
  final String status;
  final String type;

  const UpcomingAppointmentData({
    required this.doctorName,
    this.doctorAvatarUrl,
    this.specialty = 'General',
    required this.scheduledAt,
    this.status = 'pending',
    this.type = 'in_person',
  });
}

class DoctorInfo {
  final String id;
  final String name;
  final String specialty;
  final double? consultationFee;
  final String? clinicAddress;
  final String? avatarUrl;

  const DoctorInfo({
    required this.id,
    required this.name,
    this.specialty = 'General',
    this.consultationFee,
    this.clinicAddress,
    this.avatarUrl,
  });
}

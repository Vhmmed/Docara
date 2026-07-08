class PatientSummaryEntity {
  final String patientId;
  final String fullName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final int totalVisits;
  final int visitsThisYear;
  final int visitsThisMonth;
  final DateTime? lastVisitDate;

  const PatientSummaryEntity({
    required this.patientId,
    required this.fullName,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.totalVisits = 0,
    this.visitsThisYear = 0,
    this.visitsThisMonth = 0,
    this.lastVisitDate,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}

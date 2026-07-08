import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/appointment_data.dart';
export 'models/appointment_data.dart';

/// Supabase queries for appointments.
class AppointmentService {
  AppointmentService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Merge doctor/patient profiles + specialties into raw appointment rows.
  static Future<List<AppointmentData>> _mergeProfiles(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final doctorIds =
        rows.map((r) => r['doctor_id'] as String).toSet();
    final patientIds =
        rows.map((r) => r['patient_id'] as String).toSet();
    final allIds = {...doctorIds, ...patientIds}.toSet();

    // Fetch all profiles and filter in Dart
    final allProfiles = await _client.from('profiles').select('id, full_name, avatar_url');
    final profileMap = <String, String>{};
    final profileAvatarUrlMap = <String, String?>{};
    for (final p in allProfiles) {
      final id = p['id'] as String;
      if (allIds.contains(id)) {
        profileMap[id] = p['full_name'] as String? ?? 'Unknown';
        profileAvatarUrlMap[id] = p['avatar_url'] as String?;
      }
    }

    // Fetch all doctors and filter in Dart
    final allDoctors =
        await _client.from('doctors').select('id, specialty_id, clinic_address, consultation_fee, avatar_url');
    final doctorMap = <String, Map<String, dynamic>>{};
    final specIds = <String>{};
    for (final d in allDoctors) {
      final id = d['id'] as String;
      if (doctorIds.contains(id)) {
        doctorMap[id] = Map<String, dynamic>.from(d);
        final specId = d['specialty_id'] as String?;
        if (specId != null && specId.isNotEmpty) {
          specIds.add(specId);
        }
      }
    }

    // Fetch specialties
    final allSpecialties = await _client.from('specialties').select('id, name');
    final specialtyMap = <String, String>{};
    for (final s in allSpecialties) {
      final id = s['id'] as String;
      if (specIds.contains(id)) {
        specialtyMap[id] = s['name'] as String;
      }
    }

    return rows.map((r) {
      final doctorId = r['doctor_id'] as String;
      final doctorRow = doctorMap[doctorId] ?? <String, dynamic>{};
      final specId = doctorRow['specialty_id'] as String? ?? '';

      final patientId = r['patient_id'] as String;
      return AppointmentData(
        id: r['id'] as String,
        patientId: patientId,
        doctorId: doctorId,
        scheduledAt: DateTime.parse(r['scheduled_at'] as String),
        status: r['status'] as String? ?? 'pending',
        type: r['type'] as String? ?? 'in_person',
        notes: r['notes'] as String?,
        fee: (r['fee'] as num?)?.toDouble() ?? 0,
        isPaid: r['is_paid'] as bool? ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
        doctorName: profileMap[doctorId] ?? 'Unknown Doctor',
        specialty: specialtyMap[specId] ?? 'General',
        location: doctorRow['clinic_address'] as String? ?? '',
        avatarUrl: profileAvatarUrlMap[doctorId] ?? doctorRow['avatar_url'] as String?,
        patientName: profileMap[patientId] ?? 'Unknown Patient',
        patientAvatarUrl: profileAvatarUrlMap[patientId],
      );
    }).toList();
  }

  /// Fetch the single next upcoming appointment for a patient.
  static Future<Map<String, dynamic>?> getPatientUpcomingAppointment(
    String patientId,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await _client
        .from('appointments')
        .select('doctor_id, scheduled_at, status, type')
        .eq('patient_id', patientId)
        .gte('scheduled_at', now)
        .order('scheduled_at', ascending: true)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;

    final row = list.first;
    final doctorId = row['doctor_id'] as String;

    final profile =
        await _client.from('profiles').select('full_name, avatar_url').eq('id', doctorId).maybeSingle();
    final doctorName = profile?['full_name'] as String? ?? 'Doctor';
    final profileAvatarUrl = profile?['avatar_url'] as String?;

    final doctor =
        await _client.from('doctors').select('specialty_id, avatar_url').eq('id', doctorId).maybeSingle();
    final specId = doctor?['specialty_id'] as String?;
    final doctorAvatarUrl = doctor?['avatar_url'] as String?;

    final avatarUrl = profileAvatarUrl ?? doctorAvatarUrl;

    String specialty = 'General';
    if (specId != null && specId.isNotEmpty) {
      final spec =
          await _client.from('specialties').select('name').eq('id', specId).maybeSingle();
      specialty = spec?['name'] as String? ?? 'General';
    }

    return <String, dynamic>{
      'doctorName': doctorName,
      'doctorAvatarUrl': avatarUrl,
      'specialty': specialty,
      'scheduledAt': DateTime.parse(row['scheduled_at'] as String),
      'status': row['status'] as String? ?? 'pending',
      'type': row['type'] as String? ?? 'in_person',
    };
  }

  /// Fetch appointments for a patient.
  static Future<List<AppointmentData>> getPatientAppointments(
    String patientId,
  ) async {
    final rows = await _client
        .from('appointments')
        .select()
        .eq('patient_id', patientId)
        .order('scheduled_at', ascending: false);

    return _mergeProfiles((rows as List).cast<Map<String, dynamic>>());
  }

  /// Fetch appointments for a doctor.
  static Future<List<AppointmentData>> getDoctorAppointments(
    String doctorId,
  ) async {
    final rows = await _client
        .from('appointments')
        .select()
        .eq('doctor_id', doctorId)
        .order('scheduled_at', ascending: false);

    return _mergeProfiles((rows as List).cast<Map<String, dynamic>>());
  }

  /// Fetch all appointments (admin view).
  static Future<List<AppointmentData>> getAllAppointments() async {
    final rows = await _client
        .from('appointments')
        .select()
        .order('scheduled_at', ascending: false);

    return _mergeProfiles((rows as List).cast<Map<String, dynamic>>());
  }

  /// Book a new appointment.
  static Future<void> bookAppointment({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    required String type,
    String? notes,
    required double fee,
  }) async {
    await _client.from('appointments').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'type': type,
      'notes': notes ?? '',
      'fee': fee,
      'status': 'pending',
      'is_paid': false,
    });
  }

  /// Cancel an appointment.
  static Future<void> cancelAppointment(String id) async {
    await _client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  /// Update appointment status (doctor/admin).
  static Future<void> updateStatus(String id, String status) async {
    await _client
        .from('appointments')
        .update({'status': status})
        .eq('id', id);
  }

  /// Fetch distinct patients for a doctor, based on appointment history.
  static Future<List<Map<String, dynamic>>> getDoctorPatients(
    String doctorId,
  ) async {
    final rows = await _client
        .from('appointments')
        .select('patient_id, scheduled_at')
        .eq('doctor_id', doctorId)
        .order('scheduled_at', ascending: false);

    final patientList = (rows as List).cast<Map<String, dynamic>>();
    if (patientList.isEmpty) return [];

    // Aggregate: count per patient, latest visit
    final countMap = <String, int>{};
    final lastVisitMap = <String, DateTime>{};
    for (final r in patientList) {
      final pid = r['patient_id'] as String;
      final date = DateTime.parse(r['scheduled_at'] as String);
      countMap[pid] = (countMap[pid] ?? 0) + 1;
      if (!lastVisitMap.containsKey(pid) ||
          date.isAfter(lastVisitMap[pid]!)) {
        lastVisitMap[pid] = date;
      }
    }

    final allPids = countMap.keys.toSet();

    final allProfiles = await _client
        .from('profiles')
        .select('id, full_name, date_of_birth, avatar_url');
    final nameMap = <String, String>{};
    final dobMap = <String, DateTime?>{};
    final avatarUrlMap = <String, String?>{};
    for (final p in allProfiles) {
      final id = p['id'] as String;
      if (allPids.contains(id)) {
        nameMap[id] = p['full_name'] as String? ?? 'Unknown Patient';
        final dobStr = p['date_of_birth'] as String?;
        dobMap[id] = dobStr != null ? DateTime.tryParse(dobStr) : null;
        avatarUrlMap[id] = p['avatar_url'] as String?;
      }
    }

    return allPids.map((pid) => <String, dynamic>{
      'id': pid,
      'name': nameMap[pid] ?? 'Unknown Patient',
      'appointmentCount': countMap[pid] ?? 0,
      'lastVisit': lastVisitMap[pid],
      'dateOfBirth': dobMap[pid],
      'avatarUrl': avatarUrlMap[pid],
    }).toList()
      ..sort((a, b) => ((b['lastVisit'] as DateTime?) ?? DateTime(2000))
          .compareTo((a['lastVisit'] as DateTime?) ?? DateTime(2000)));
  }

  /// Fetch today's appointments for a doctor (lightweight, no full merge).
  static Future<List<Map<String, dynamic>>> getDoctorTodayAppointments(
    String doctorId,
  ) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await _client
        .from('appointments')
        .select('patient_id, scheduled_at, status, type')
        .eq('doctor_id', doctorId)
        .gte('scheduled_at', dayStart.toUtc().toIso8601String())
        .lt('scheduled_at', dayEnd.toUtc().toIso8601String())
        .order('scheduled_at', ascending: true);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return [];

    final patientIds = list.map((r) => r['patient_id'] as String).toSet();
    final allProfiles = await _client.from('profiles').select('id, full_name, avatar_url');
    final nameMap = <String, String>{};
    final avatarUrlMap = <String, String?>{};
    for (final p in allProfiles) {
      final id = p['id'] as String;
      if (patientIds.contains(id)) {
        nameMap[id] = p['full_name'] as String? ?? 'Unknown';
        avatarUrlMap[id] = p['avatar_url'] as String?;
      }
    }

    return list.map((r) => <String, dynamic>{
      'patientName': nameMap[r['patient_id'] as String] ?? 'Unknown',
      'patientAvatarUrl': avatarUrlMap[r['patient_id'] as String],
      'scheduledAt': DateTime.parse(r['scheduled_at'] as String),
      'status': r['status'] as String? ?? 'pending',
      'type': r['type'] as String? ?? 'in_person',
    }).toList();
  }

  /// Appointment counts per day for the next [days] days.
  static Future<List<Map<String, dynamic>>> getDoctorDailySchedule(
    String doctorId, {
    int days = 5,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(Duration(days: days));

    final rows = await _client
        .from('appointments')
        .select('scheduled_at')
        .eq('doctor_id', doctorId)
        .gte('scheduled_at', startDate.toUtc().toIso8601String())
        .lt('scheduled_at', endDate.toUtc().toIso8601String());

    final list = (rows as List).cast<Map<String, dynamic>>();

    final countMap = <String, int>{};
    for (final r in list) {
      final dateStr = (r['scheduled_at'] as String).substring(0, 10);
      countMap[dateStr] = (countMap[dateStr] ?? 0) + 1;
    }

    return List.generate(days, (index) {
      final date = startDate.add(Duration(days: index));
      final key = DateFormat('yyyy-MM-dd').format(date);
      return <String, dynamic>{
        'date': date,
        'count': countMap[key] ?? 0,
        'isToday': index == 0,
      };
    });
  }

  /// Get the doctor's specialty name from the specialties table.
  static Future<String> getDoctorSpecialtyName(String doctorId) async {
    final doctor = await _client
        .from('doctors')
        .select('specialty_id')
        .eq('id', doctorId)
        .single();

    final specId = doctor['specialty_id'] as String?;
    if (specId == null || specId.isEmpty) return 'General';

    final spec = await _client
        .from('specialties')
        .select('name')
        .eq('id', specId)
        .single();

    return spec['name'] as String? ?? 'General';
  }

  /// Fetch approved doctors for the booking sheet.
  static Future<List<Map<String, dynamic>>> getApprovedDoctors() async {
    final doctors = await _client
        .from('doctors')
        .select('id, specialty_id, consultation_fee, clinic_address, avatar_url')
        .eq('status', 'approved');

    final doctorList = (doctors as List).cast<Map<String, dynamic>>();
    final doctorIds = doctorList.map((d) => d['id'] as String).toSet();

    if (doctorIds.isEmpty) return [];

    final allProfiles = await _client.from('profiles').select('id, full_name');
    final profileMap = <String, String>{};
    for (final p in allProfiles) {
      final id = p['id'] as String;
      if (doctorIds.contains(id)) {
        profileMap[id] = p['full_name'] as String? ?? 'Doctor';
      }
    }

    final specIds = doctorList
        .map((d) => d['specialty_id'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .map((s) => s!)
        .toSet();

    final allSpecialties = await _client.from('specialties').select('id, name');
    final specialtyMap = <String, String>{};
    for (final s in allSpecialties) {
      final id = s['id'] as String;
      if (specIds.contains(id)) {
        specialtyMap[id] = s['name'] as String;
      }
    }

    return doctorList.map((d) {
      final id = d['id'] as String;
      final specId = d['specialty_id'] as String? ?? '';
      return <String, dynamic>{
        'id': id,
        'consultation_fee': d['consultation_fee'],
        'clinic_address': d['clinic_address'],
        'avatar_url': d['avatar_url'],
        'specialty': {'name': specialtyMap[specId] ?? 'General'},
        'profile': {'full_name': profileMap[id] ?? 'Doctor'},
      };
    }).toList();
  }
}

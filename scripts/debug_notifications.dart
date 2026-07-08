// Run: dart run scripts/debug_notifications.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://knthcpjoakqubknipnis.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudGhjcGpvYWtxdWJrbmlwbmlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjQwMTksImV4cCI6MjA5NzU0MDAxOX0.9tkfZzAPo0V-keX5IP55jQujzvZ4ESnXFtv7X7qDBlM',
  );

  final client = Supabase.instance.client;

  print('=== STEP 1: Check tables exist ===');

  // Check notifications table exists
  try {
    final cnt = await client.from('notifications').select('id').limit(1);
    print('notifications table: EXISTS (found ${cnt.length} rows)');
  } catch (e) {
    print('notifications table: MISSING or error: $e');
  }

  // Check appointments table
  try {
    final appts = await client.from('appointments').select('id, status, patient_id, doctor_id').limit(5);
    print('appointments: ${appts.length} rows');
    for (final a in appts) {
      print('  id=${a['id']} status="${a['status']}" patient=${(a['patient_id'] as String).substring(0, 8)}... doctor=${(a['doctor_id'] as String).substring(0, 8)}...');
    }
  } catch (e) {
    print('appointments table error: $e');
  }

  // Check notifications count
  try {
    final notifs = await client.from('notifications').select('id, type, user_id, is_read, created_at').limit(10);
    print('notifications: ${notifs.length} rows');
    for (final n in notifs) {
      print('  id=${(n['id'] as String).substring(0, 8)}... type="${n['type']}" userId=${(n['user_id'] as String).substring(0, 8)}... isRead=${n['is_read']}');
    }
  } catch (e) {
    print('notifications query error: $e');
  }

  print('\n=== STEP 2: Check if triggers exist via pg_trigger ===');
  // We can't query pg_trigger directly via REST with anon key, but let's try
  
  // Check the actual appointments table schema for status column
  try {
    final rows = await client.from('appointments').select('status').limit(1);
    if (rows.isNotEmpty) {
      print('Appointment status value found: "${rows[0]['status']}"');
      print('Type: ${rows[0]['status'].runtimeType}');
    } else {
      print('No appointments in table - status column exists (SELECT returned empty)');
    }
  } catch (e) {
    print('Error checking appointments: $e');
  }

  print('\n=== STEP 3: Test booking an appointment and checking trigger ===');
  // We need to book an appointment to see if the trigger fires.
  // But we need a valid patient and doctor in the DB.
  // Let's first check what profiles exist.
  try {
    final profiles = await client.from('profiles').select('id, role').limit(10);
    print('Profiles found: ${profiles.length}');
    for (final p in profiles) {
      print('  id=${(p['id'] as String).substring(0, 8)}... role=${p['role']}');
    }
  } catch (e) {
    print('Profiles query error: $e');
  }

  print('\n=== DONE ===');
}

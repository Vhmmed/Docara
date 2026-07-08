-- =============================================================================
-- Row-Level Security (RLS) Policies
-- Run this in the Supabase SQL Editor AFTER all tables exist.
-- Idempotent — safe to run multiple times.
-- =============================================================================
-- Table relationships:
--   auth.users (Supabase Auth, not in RLS scope)
--     ↑ id
--     └── profiles.id  (1:1)
--          ↑ id
--          ├── doctors.id  (1:1, only if role='doctor')
--          │    ├── appointments.doctor_id
--          │    ├── medical_records.doctor_id  (nullable)
--          │    ├── conversations.doctor_id
--          │    └── doctor_availability.doctor_id
--          ├── appointments.patient_id
--          ├── medical_records.patient_id
--          ├── conversations.patient_id
--          └── messages.sender_id
-- =============================================================================

-- =============================================================================
-- 1. PROFILES
--    - Patients: read/update own; insert own row at signup
--    - Doctors: same as patients
--    - Admins: full CRUD on all profiles
-- =============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own profile" ON profiles;
CREATE POLICY "Users view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins view all profiles" ON profiles;
CREATE POLICY "Admins view all profiles"
  ON profiles FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Users insert own profile" ON profiles;
CREATE POLICY "Users insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users update own profile" ON profiles;
CREATE POLICY "Users update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins update any profile" ON profiles;
CREATE POLICY "Admins update any profile"
  ON profiles FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins delete profiles" ON profiles;
CREATE POLICY "Admins delete profiles"
  ON profiles FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 2. DOCTORS
--    - Everyone: SELECT (public directory)
--    - Doctor: INSERT own row, UPDATE own data
--    - Admin: UPDATE (verify/reject), DELETE
-- =============================================================================
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view doctors" ON doctors;
CREATE POLICY "Everyone can view doctors"
  ON doctors FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Doctors insert own profile" ON doctors;
CREATE POLICY "Doctors insert own profile"
  ON doctors FOR INSERT
  WITH CHECK (
    auth.uid() = id
    AND EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
  );

DROP POLICY IF EXISTS "Doctors update own profile" ON doctors;
CREATE POLICY "Doctors update own profile"
  ON doctors FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins update doctors" ON doctors;
CREATE POLICY "Admins update doctors"
  ON doctors FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins delete doctors" ON doctors;
CREATE POLICY "Admins delete doctors"
  ON doctors FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 3. SPECIALTIES (public reference data)
--    - Everyone: SELECT
--    - Admin: INSERT, UPDATE, DELETE
-- =============================================================================
ALTER TABLE specialties ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view specialties" ON specialties;
CREATE POLICY "Everyone can view specialties"
  ON specialties FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins manage specialties" ON specialties;
CREATE POLICY "Admins manage specialties"
  ON specialties FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins update specialties" ON specialties;
CREATE POLICY "Admins update specialties"
  ON specialties FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins delete specialties" ON specialties;
CREATE POLICY "Admins delete specialties"
  ON specialties FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 4. DOCTOR_AVAILABILITY
--    - Everyone: SELECT (public for booking)
--    - Doctor: INSERT/UPDATE/DELETE own availability
--    - Admin: full CRUD
-- =============================================================================
ALTER TABLE doctor_availability ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view availability" ON doctor_availability;
CREATE POLICY "Everyone can view availability"
  ON doctor_availability FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Doctors insert own availability" ON doctor_availability;
CREATE POLICY "Doctors insert own availability"
  ON doctor_availability FOR INSERT
  WITH CHECK (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Doctors update own availability" ON doctor_availability;
CREATE POLICY "Doctors update own availability"
  ON doctor_availability FOR UPDATE
  USING (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Doctors delete own availability" ON doctor_availability;
CREATE POLICY "Doctors delete own availability"
  ON doctor_availability FOR DELETE
  USING (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Admins manage availability" ON doctor_availability;
CREATE POLICY "Admins manage availability"
  ON doctor_availability FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 5. MEDICAL_RECORDS
--    - Patient: SELECT own records
--    - Doctor: SELECT records they created, INSERT new records, UPDATE own
--    - Admin: full CRUD
-- =============================================================================
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients view own records" ON medical_records;
CREATE POLICY "Patients view own records"
  ON medical_records FOR SELECT
  USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Doctors view own records" ON medical_records;
CREATE POLICY "Doctors view own records"
  ON medical_records FOR SELECT
  USING (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Admins view all records" ON medical_records;
CREATE POLICY "Admins view all records"
  ON medical_records FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Doctors create records" ON medical_records;
CREATE POLICY "Doctors create records"
  ON medical_records FOR INSERT
  WITH CHECK (
    auth.uid() = doctor_id
    AND EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'
    )
  );

DROP POLICY IF EXISTS "Doctors update own records" ON medical_records;
CREATE POLICY "Doctors update own records"
  ON medical_records FOR UPDATE
  USING (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Admins update any record" ON medical_records;
CREATE POLICY "Admins update any record"
  ON medical_records FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins delete records" ON medical_records;
CREATE POLICY "Admins delete records"
  ON medical_records FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 6. CONVERSATIONS (chat)
--    - Participants: SELECT, INSERT, UPDATE their own conversations
--    - Admin: DELETE (content moderation)
-- =============================================================================
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants view conversations" ON conversations;
CREATE POLICY "Participants view conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = patient_id OR auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Participants create conversations" ON conversations;
CREATE POLICY "Participants create conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = patient_id OR auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Participants update conversations" ON conversations;
CREATE POLICY "Participants update conversations"
  ON conversations FOR UPDATE
  USING (auth.uid() = patient_id OR auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = patient_id OR auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Admins delete conversations" ON conversations;
CREATE POLICY "Admins delete conversations"
  ON conversations FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- 7. MESSAGES
--    - Participants: SELECT/INSERT messages in their conversations
--    - Sender: UPDATE own messages (mark as read, edit)
--    - Admin: DELETE (content moderation)
-- =============================================================================
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants view messages" ON messages;
CREATE POLICY "Participants view messages"
  ON messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = conversation_id
    AND (c.patient_id = auth.uid() OR c.doctor_id = auth.uid())
  ));

DROP POLICY IF EXISTS "Participants send messages" ON messages;
CREATE POLICY "Participants send messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
      AND (c.patient_id = auth.uid() OR c.doctor_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Sender updates own messages" ON messages;
CREATE POLICY "Sender updates own messages"
  ON messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "Admins delete messages" ON messages;
CREATE POLICY "Admins delete messages"
  ON messages FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));


-- =============================================================================
-- VERIFICATION: list all policies
-- =============================================================================
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

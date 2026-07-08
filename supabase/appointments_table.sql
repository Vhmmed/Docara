-- =============================================================================
-- Appointments table
-- Run this in the Supabase SQL Editor.
-- =============================================================================

CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'rejected')),
  type TEXT NOT NULL DEFAULT 'in_person'
    CHECK (type IN ('in_person', 'video')),
  notes TEXT,
  fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  is_paid BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- Migration: add columns that may be missing if the table was created by an
-- earlier version of this script (CREATE TABLE IF NOT EXISTS skips existing).
-- =============================================================================
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS fee DECIMAL(10, 2) NOT NULL DEFAULT 0;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS is_paid BOOLEAN NOT NULL DEFAULT FALSE;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments (patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments (doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments (scheduled_at DESC);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments (status);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_appointments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_appointments_updated_at ON appointments;
CREATE TRIGGER trg_appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_appointments_updated_at();

-- =============================================================================
-- Row-Level Security
-- =============================================================================
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients view own appointments" ON appointments;
CREATE POLICY "Patients view own appointments"
  ON appointments FOR SELECT
  USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Doctors view own appointments" ON appointments;
CREATE POLICY "Doctors view own appointments"
  ON appointments FOR SELECT
  USING (auth.uid() = doctor_id);

DROP POLICY IF EXISTS "Admins view all appointments" ON appointments;
CREATE POLICY "Admins view all appointments"
  ON appointments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Patients create appointments" ON appointments;
CREATE POLICY "Patients create appointments"
  ON appointments FOR INSERT
  WITH CHECK (
    auth.uid() = patient_id
    AND status = 'pending'
  );

DROP POLICY IF EXISTS "Patients cancel own appointments" ON appointments;
CREATE POLICY "Patients cancel own appointments"
  ON appointments FOR UPDATE
  USING (auth.uid() = patient_id AND status = 'pending')
  WITH CHECK (auth.uid() = patient_id AND status = 'cancelled');

DROP POLICY IF EXISTS "Doctors update own appointments" ON appointments;
CREATE POLICY "Doctors update own appointments"
  ON appointments FOR UPDATE
  USING (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

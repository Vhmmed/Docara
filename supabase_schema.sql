-- =============================================================================
-- Migration: Create chat tables (conversations + messages)
-- =============================================================================

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(patient_id, doctor_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
  ON messages (conversation_id);

CREATE INDEX IF NOT EXISTS idx_messages_created_at
  ON messages (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_unread
  ON messages (conversation_id, is_read)
  WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_conversations_patient_id
  ON conversations (patient_id);

CREATE INDEX IF NOT EXISTS idx_conversations_doctor_id
  ON conversations (doctor_id);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;
-- Allow conversation participants to view each other's profiles
-- (needed so ChatDetailPage can fetch the other participant's last_seen_at)
DROP POLICY IF EXISTS "Conversation participants view each others profiles" ON profiles;
CREATE POLICY "Conversation participants view each others profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE (c.patient_id = auth.uid() AND c.doctor_id = profiles.id)
         OR (c.doctor_id = auth.uid() AND c.patient_id = profiles.id)
    )
  );
-- =============================================================================
-- Migration: Add UPDATE policy on profiles + ensure SELECT covers own profile
-- =============================================================================

-- Users can update their own profile (needed for last_seen_at tracking)
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Also ensure users can SELECT their own profile (the conversation-participant
-- policy alone doesn't cover self-view since a user isn't in a conversation
-- with themselves)
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
-- Create notifications table (if not already present)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add data column in case the table was previously created without it
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications (user_id, is_read) WHERE is_read = false;

-- RLS (safe to repeat)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON public.notifications;
CREATE POLICY "Authenticated users can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- Trigger: new appointment booked → notify doctor
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_appointment_booked()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    NEW.doctor_id,
    'appointment_booked',
    'New Appointment Booking',
    'A new appointment has been booked.',
    jsonb_build_object('appointment_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_appointment_booked ON public.appointments;
CREATE TRIGGER on_appointment_booked
  AFTER INSERT ON public.appointments
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION public.handle_appointment_booked();

-- ---------------------------------------------------------------------------
-- Trigger: appointment confirmed → notify patient
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_appointment_confirmed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    NEW.patient_id,
    'appointment_confirmed',
    'Appointment Confirmed',
    'Your appointment has been confirmed.',
    jsonb_build_object('appointment_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_appointment_confirmed ON public.appointments;
CREATE TRIGGER on_appointment_confirmed
  AFTER UPDATE OF status ON public.appointments
  FOR EACH ROW
  WHEN (NEW.status = 'confirmed' AND OLD.status = 'pending')
  EXECUTE FUNCTION public.handle_appointment_confirmed();

-- ---------------------------------------------------------------------------
-- Trigger: appointment cancelled → notify both parties
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_appointment_cancelled()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES
    (NEW.patient_id, 'appointment_cancelled', 'Appointment Cancelled', 'Your appointment has been cancelled.', jsonb_build_object('appointment_id', NEW.id)),
    (NEW.doctor_id, 'appointment_cancelled', 'Appointment Cancelled', 'An appointment has been cancelled.', jsonb_build_object('appointment_id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_appointment_cancelled ON public.appointments;
CREATE TRIGGER on_appointment_cancelled
  AFTER UPDATE OF status ON public.appointments
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION public.handle_appointment_cancelled();
-- Fix the existing notifications_type_check constraint to allow appointment_* types
-- The existing table (created externally) had a CHECK constraint on type column
-- that only allows certain type values. We need to drop and recreate it.

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Recreate with all supported types
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('message', 'appointment_booked', 'appointment_confirmed', 'appointment_cancelled'));

-- Also ensure RLS INSERT policy allows our SECURITY DEFINER trigger to insert
-- The trigger bypasses RLS, but direct inserts via the app need this too
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON public.notifications;
CREATE POLICY "Authenticated users can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- Ensure the authenticated user can always SELECT their own notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
-- ---------------------------------------------------------------------------
-- Trigger: new chat message → notify the other conversation participant
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_recipient_id UUID;
  v_sender_name TEXT;
  v_sender_avatar_url TEXT;
  v_sender_role TEXT;
BEGIN
  -- Determine the recipient (the participant who did NOT send the message)
  SELECT
    CASE
      WHEN c.patient_id = NEW.sender_id THEN c.doctor_id
      ELSE c.patient_id
    END INTO v_recipient_id
  FROM public.conversations c
  WHERE c.id = NEW.conversation_id;

  IF v_recipient_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get sender's profile info
  SELECT full_name, avatar_url, role INTO v_sender_name, v_sender_avatar_url, v_sender_role
  FROM public.profiles
  WHERE id = NEW.sender_id;

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    v_recipient_id,
    'message',
    'New message from ' || COALESCE(v_sender_name, 'Someone'),
    NEW.content,
    jsonb_build_object(
      'conversation_id', NEW.conversation_id,
      'message_id', NEW.id,
      'sender_id', NEW.sender_id,
      'sender_name', v_sender_name,
      'sender_avatar_url', v_sender_avatar_url,
      'sender_role', v_sender_role
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_message();

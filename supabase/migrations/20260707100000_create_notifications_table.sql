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

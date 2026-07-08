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

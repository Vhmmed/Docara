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

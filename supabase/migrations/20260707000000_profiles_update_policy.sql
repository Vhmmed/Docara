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

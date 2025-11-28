-- Security Fix: Restrict profiles table access to prevent employee data harvesting
-- Drop the overly permissive policy
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;

-- Create admin policy for profiles (check if it doesn't exist)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' 
    AND policyname = 'Admins can view all profiles'
  ) THEN
    CREATE POLICY "Admins can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (has_role(auth.uid(), 'admin'::app_role));
  END IF;
END $$;

-- Security Fix: Make audit logs append-only (immutable)
-- Explicitly deny UPDATE operations on audit logs
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'audit_logs' 
    AND policyname = 'No one can update audit logs'
  ) THEN
    CREATE POLICY "No one can update audit logs"
    ON public.audit_logs
    FOR UPDATE
    USING (false);
  END IF;
END $$;

-- Explicitly deny DELETE operations on audit logs
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'audit_logs' 
    AND policyname = 'No one can delete audit logs'
  ) THEN
    CREATE POLICY "No one can delete audit logs"
    ON public.audit_logs
    FOR DELETE
    USING (false);
  END IF;
END $$;

-- Security Enhancement: Mask confidential vote tallies during active voting
-- Create a secure view that hides vote counts for confidential ballots
CREATE OR REPLACE VIEW voting_proposals_safe AS
SELECT 
  id,
  committee_id,
  meeting_id,
  agenda_item_id,
  title,
  description,
  proposal_type,
  proposed_by_id,
  voting_method,
  required_majority,
  voting_start_time,
  voting_end_time,
  status,
  quorum_required,
  quorum_achieved,
  confidential_voting,
  result,
  created_at,
  updated_at,
  -- Mask vote counts if confidential voting is enabled and voting is still open
  CASE 
    WHEN confidential_voting = true AND status NOT IN ('closed', 'completed') THEN NULL
    ELSE yes_votes 
  END AS yes_votes,
  CASE 
    WHEN confidential_voting = true AND status NOT IN ('closed', 'completed') THEN NULL
    ELSE no_votes 
  END AS no_votes,
  CASE 
    WHEN confidential_voting = true AND status NOT IN ('closed', 'completed') THEN NULL
    ELSE abstain_votes 
  END AS abstain_votes,
  -- Show total votes count (doesn't reveal how people voted)
  total_votes
FROM public.voting_proposals;

-- Grant access to the secure view
GRANT SELECT ON voting_proposals_safe TO authenticated;

-- Add comment documenting the security enhancement
COMMENT ON VIEW voting_proposals_safe IS 'Secure view that masks vote tallies during confidential voting to prevent vote influencing. Use this view instead of direct table access for displaying proposal information to users.';
-- Fix Security Definer View: voting_proposals_safe
-- Change from SECURITY DEFINER (default) to SECURITY INVOKER
-- This ensures RLS policies are evaluated using the querying user's permissions

-- Drop and recreate the view with security_invoker option
DROP VIEW IF EXISTS voting_proposals_safe;

CREATE VIEW voting_proposals_safe 
WITH (security_invoker = on)
AS
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
  -- Conditionally mask vote tallies for confidential ballots
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
COMMENT ON VIEW voting_proposals_safe IS 'Secure view that masks vote tallies during confidential voting to prevent vote influencing. Uses SECURITY INVOKER to enforce RLS policies of the querying user. Use this view instead of direct table access for displaying proposal information to users.';
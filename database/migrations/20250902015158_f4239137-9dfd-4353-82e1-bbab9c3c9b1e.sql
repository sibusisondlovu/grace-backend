-- Fix the search_path security issue for the update_vote_counts function
CREATE OR REPLACE FUNCTION public.update_vote_counts()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.voting_proposals
  SET 
    total_votes = (
      SELECT COUNT(*) FROM public.vote_records 
      WHERE proposal_id = COALESCE(NEW.proposal_id, OLD.proposal_id)
    ),
    yes_votes = (
      SELECT COUNT(*) FROM public.vote_records 
      WHERE proposal_id = COALESCE(NEW.proposal_id, OLD.proposal_id) 
      AND vote_choice = 'yes'
    ),
    no_votes = (
      SELECT COUNT(*) FROM public.vote_records 
      WHERE proposal_id = COALESCE(NEW.proposal_id, OLD.proposal_id) 
      AND vote_choice = 'no'
    ),
    abstain_votes = (
      SELECT COUNT(*) FROM public.vote_records 
      WHERE proposal_id = COALESCE(NEW.proposal_id, OLD.proposal_id) 
      AND vote_choice = 'abstain'
    )
  WHERE id = COALESCE(NEW.proposal_id, OLD.proposal_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$;
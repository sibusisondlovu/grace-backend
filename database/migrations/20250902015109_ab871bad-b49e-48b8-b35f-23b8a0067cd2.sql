-- Create voting proposals table
CREATE TABLE public.voting_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  committee_id uuid REFERENCES public.committees(id) ON DELETE CASCADE NOT NULL,
  meeting_id uuid REFERENCES public.meetings(id) ON DELETE SET NULL,
  agenda_item_id uuid REFERENCES public.agenda_items(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  proposal_type text NOT NULL DEFAULT 'motion',
  proposed_by_id uuid REFERENCES auth.users(id) NOT NULL,
  voting_method text NOT NULL DEFAULT 'simple_majority',
  required_majority numeric DEFAULT 0.5,
  voting_start_time timestamp with time zone DEFAULT now(),
  voting_end_time timestamp with time zone,
  status text NOT NULL DEFAULT 'open',
  quorum_required integer,
  quorum_achieved boolean,
  total_votes integer DEFAULT 0,
  yes_votes integer DEFAULT 0,
  no_votes integer DEFAULT 0,
  abstain_votes integer DEFAULT 0,
  result text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create vote records table
CREATE TABLE public.vote_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id uuid REFERENCES public.voting_proposals(id) ON DELETE CASCADE NOT NULL,
  voter_id uuid REFERENCES auth.users(id) NOT NULL,
  vote_choice text NOT NULL CHECK (vote_choice IN ('yes', 'no', 'abstain')),
  cast_at timestamp with time zone NOT NULL DEFAULT now(),
  proxy_voter_id uuid REFERENCES auth.users(id),
  UNIQUE(proposal_id, voter_id)
);

-- Enable RLS
ALTER TABLE public.voting_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vote_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies for voting_proposals
CREATE POLICY "Committee members can view proposals"
ON public.voting_proposals
FOR SELECT
USING (
  has_committee_access(auth.uid(), committee_id) OR 
  has_role(auth.uid(), 'admin'::app_role)
);

CREATE POLICY "Committee members can create proposals"
ON public.voting_proposals
FOR INSERT
WITH CHECK (
  has_committee_access(auth.uid(), committee_id) OR 
  has_role(auth.uid(), 'admin'::app_role)
);

CREATE POLICY "Proposal authors and admins can update proposals"
ON public.voting_proposals
FOR UPDATE
USING (
  proposed_by_id = auth.uid() OR 
  has_role(auth.uid(), 'admin'::app_role)
);

-- RLS Policies for vote_records
CREATE POLICY "Committee members can view vote records"
ON public.vote_records
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.voting_proposals p
    WHERE p.id = vote_records.proposal_id
    AND (has_committee_access(auth.uid(), p.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
  )
);

CREATE POLICY "Eligible voters can cast votes"
ON public.vote_records
FOR INSERT
WITH CHECK (
  voter_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.voting_proposals p
    WHERE p.id = vote_records.proposal_id
    AND has_committee_access(auth.uid(), p.committee_id)
    AND p.status = 'open'
  )
);

CREATE POLICY "Voters can update their own votes"
ON public.vote_records
FOR UPDATE
USING (
  voter_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.voting_proposals p
    WHERE p.id = vote_records.proposal_id
    AND p.status = 'open'
  )
);

-- Create triggers for updated_at
CREATE TRIGGER update_voting_proposals_updated_at
  BEFORE UPDATE ON public.voting_proposals
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to update vote counts
CREATE OR REPLACE FUNCTION public.update_vote_counts()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Create trigger to update vote counts
CREATE TRIGGER update_vote_counts_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.vote_records
  FOR EACH ROW
  EXECUTE FUNCTION public.update_vote_counts();
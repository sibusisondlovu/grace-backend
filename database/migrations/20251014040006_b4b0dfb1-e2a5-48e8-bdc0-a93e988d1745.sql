-- Drop existing policy for managing meetings
DROP POLICY IF EXISTS "Committee members can manage meetings" ON public.meetings;

-- Create updated policy that includes committee leadership
CREATE POLICY "Committee members and leadership can manage meetings" 
ON public.meetings 
FOR ALL 
USING (
  has_committee_access(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
  OR check_committee_leadership(auth.uid(), committee_id)
)
WITH CHECK (
  has_committee_access(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
  OR check_committee_leadership(auth.uid(), committee_id)
);
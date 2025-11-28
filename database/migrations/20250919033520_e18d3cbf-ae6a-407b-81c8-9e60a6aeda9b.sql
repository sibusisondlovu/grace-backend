-- Fix security vulnerability: Restrict access to committee member sensitive information
-- Drop the overly permissive policy that allows public access to all committee members
DROP POLICY IF EXISTS "Users can view all committee members" ON public.committee_members;

-- Create more restrictive policies that protect sensitive political information
-- Policy 1: Committee members can view other members of the same committees they belong to
CREATE POLICY "Committee members can view same committee members" 
ON public.committee_members 
FOR SELECT 
USING (
  -- User can see members of committees they belong to
  EXISTS (
    SELECT 1 FROM public.committee_members cm
    WHERE cm.user_id = auth.uid() 
    AND cm.committee_id = committee_members.committee_id
    AND (cm.end_date IS NULL OR cm.end_date >= CURRENT_DATE)
  )
  -- Or user is a committee chair/deputy chair
  OR EXISTS (
    SELECT 1 FROM public.committees c
    WHERE c.id = committee_members.committee_id 
    AND (c.chair_id = auth.uid() OR c.deputy_chair_id = auth.uid())
  )
  -- Or user is an admin
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Policy 2: Users can view their own committee membership information
CREATE POLICY "Users can view own committee memberships" 
ON public.committee_members 
FOR SELECT 
USING (user_id = auth.uid());

-- Add audit logging for sensitive committee member data access
CREATE OR REPLACE FUNCTION public.log_committee_member_access()
RETURNS TRIGGER AS $$
BEGIN
  -- Log when sensitive political information is accessed
  IF TG_OP = 'SELECT' AND (NEW.party_affiliation IS NOT NULL OR NEW.ward_number IS NOT NULL) THEN
    PERFORM public.log_audit_event(
      'sensitive_data_access',
      'committee_members',
      NEW.id,
      NULL,
      jsonb_build_object(
        'accessed_user_id', NEW.user_id,
        'party_affiliation_accessed', (NEW.party_affiliation IS NOT NULL),
        'ward_number_accessed', (NEW.ward_number IS NOT NULL)
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
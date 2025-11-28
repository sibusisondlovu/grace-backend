-- Fix infinite recursion in committee_members policies
-- Drop the problematic policies first
DROP POLICY IF EXISTS "Committee members can view same committee members" ON public.committee_members;
DROP POLICY IF EXISTS "Users can view own committee memberships" ON public.committee_members;

-- Create security definer function to check committee membership without recursion
CREATE OR REPLACE FUNCTION public.check_user_committee_membership(_user_id uuid, _committee_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.committee_members
    WHERE user_id = _user_id
      AND committee_id = _committee_id
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
  )
$$;

-- Create security definer function to check if user is committee chair/deputy
CREATE OR REPLACE FUNCTION public.check_committee_leadership(_user_id uuid, _committee_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.committees
    WHERE id = _committee_id
      AND (chair_id = _user_id OR deputy_chair_id = _user_id)
  )
$$;

-- Create new non-recursive policies using the security definer functions
CREATE POLICY "Committee members can view same committee members" 
ON public.committee_members 
FOR SELECT 
USING (
  -- User can see members of committees they belong to
  public.check_user_committee_membership(auth.uid(), committee_members.committee_id)
  -- Or user is a committee chair/deputy chair
  OR public.check_committee_leadership(auth.uid(), committee_members.committee_id)
  -- Or user is an admin
  OR has_role(auth.uid(), 'admin'::app_role)
  -- Or it's their own membership
  OR user_id = auth.uid()
);
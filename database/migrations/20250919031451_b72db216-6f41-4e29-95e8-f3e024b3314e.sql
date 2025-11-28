-- Fix critical security issues identified in security review

-- 1. Fix profiles table RLS policies - restrict admin access to be more granular
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Create more restrictive admin access - only system admins can view all profiles
CREATE POLICY "System admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (
  (auth.uid() = user_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- 2. Fix voting privacy - add confidential voting support
ALTER TABLE public.voting_proposals 
ADD COLUMN confidential_voting boolean DEFAULT false;

-- Update vote records policies to protect privacy for confidential votes
DROP POLICY IF EXISTS "Committee members can view vote records" ON public.vote_records;

CREATE POLICY "Committee members can view vote records with privacy" 
ON public.vote_records 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM voting_proposals p 
    WHERE p.id = vote_records.proposal_id 
    AND (
      has_committee_access(auth.uid(), p.committee_id) 
      OR has_role(auth.uid(), 'admin'::app_role)
    )
    AND (
      -- For confidential votes, only show your own vote or if you're admin
      (p.confidential_voting = false) 
      OR (p.confidential_voting = true AND (vote_records.voter_id = auth.uid() OR has_role(auth.uid(), 'admin'::app_role)))
    )
  )
);

-- 3. Restrict user_roles visibility - users should only see relevant roles
DROP POLICY IF EXISTS "Users can view all roles" ON public.user_roles;

-- Create more restrictive role visibility policies
CREATE POLICY "Users can view own roles" 
ON public.user_roles 
FOR SELECT 
USING (user_id = auth.uid());

CREATE POLICY "Committee chairs can view committee member roles" 
ON public.user_roles 
FOR SELECT 
USING (
  committee_id IS NOT NULL 
  AND EXISTS (
    SELECT 1 FROM committees c 
    WHERE c.id = user_roles.committee_id 
    AND (c.chair_id = auth.uid() OR c.deputy_chair_id = auth.uid())
  )
);

CREATE POLICY "Admins can view all roles" 
ON public.user_roles 
FOR SELECT 
USING (has_role(auth.uid(), 'admin'::app_role));

-- 4. Add audit logging table for sensitive operations
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  table_name text NOT NULL,
  record_id uuid,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS on audit logs
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs" 
ON public.audit_logs 
FOR SELECT 
USING (has_role(auth.uid(), 'admin'::app_role));

-- 5. Add function to log sensitive operations
CREATE OR REPLACE FUNCTION public.log_audit_event(
  _action text,
  _table_name text,
  _record_id uuid DEFAULT NULL,
  _old_values jsonb DEFAULT NULL,
  _new_values jsonb DEFAULT NULL
) RETURNS void 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.audit_logs (
    user_id, 
    action, 
    table_name, 
    record_id, 
    old_values, 
    new_values
  ) VALUES (
    auth.uid(),
    _action,
    _table_name,
    _record_id,
    _old_values,
    _new_values
  );
END;
$$;
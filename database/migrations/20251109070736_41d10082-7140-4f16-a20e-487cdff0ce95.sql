-- Multi-tenancy Part 2: Security functions and RLS policies (Fixed)

-- Create security definer functions for organization checks
CREATE OR REPLACE FUNCTION public.is_super_admin(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT has_role(_user_id, 'super_admin'::app_role);
$$;

CREATE OR REPLACE FUNCTION public.get_user_organization(_user_id UUID)
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organization_id 
  FROM public.profiles 
  WHERE user_id = _user_id
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.can_access_organization(_user_id UUID, _organization_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    is_super_admin(_user_id) OR 
    get_user_organization(_user_id) = _organization_id;
$$;

-- RLS policies for organizations
CREATE POLICY "Super admins can manage all organizations"
ON public.organizations FOR ALL
USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view their own organization"
ON public.organizations FOR SELECT
USING (get_user_organization(auth.uid()) = id OR is_super_admin(auth.uid()));

-- RLS policies for subscriptions
CREATE POLICY "Super admins can manage all subscriptions"
ON public.subscriptions FOR ALL
USING (is_super_admin(auth.uid()));

CREATE POLICY "Organization admins can view their subscription"
ON public.subscriptions FOR SELECT
USING (
  can_access_organization(auth.uid(), organization_id) AND 
  has_role(auth.uid(), 'admin'::app_role)
);

-- Update existing RLS policies to include organization isolation
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view organization profiles" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON public.profiles;

CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view organization profiles"
ON public.profiles FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) AND 
  can_access_organization(auth.uid(), organization_id)
);

CREATE POLICY "Super admins can view all profiles"
ON public.profiles FOR SELECT
USING (is_super_admin(auth.uid()));

-- Committees
DROP POLICY IF EXISTS "Users can view organization committees" ON public.committees;
DROP POLICY IF EXISTS "Admins and chairs can manage organization committees" ON public.committees;

CREATE POLICY "Users can view organization committees"
ON public.committees FOR SELECT
USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins and chairs can manage organization committees"
ON public.committees FOR ALL
USING (
  can_access_organization(auth.uid(), organization_id) AND
  (has_role(auth.uid(), 'admin'::app_role) OR chair_id = auth.uid() OR deputy_chair_id = auth.uid())
);

-- Meetings
DROP POLICY IF EXISTS "Committee members can view organization meetings" ON public.meetings;
DROP POLICY IF EXISTS "Public can view public organization meetings" ON public.meetings;
DROP POLICY IF EXISTS "Committee members can view committee meetings" ON public.meetings;
DROP POLICY IF EXISTS "Public can view public meetings" ON public.meetings;

CREATE POLICY "Committee members can view organization meetings"
ON public.meetings FOR SELECT
USING (
  can_access_organization(auth.uid(), organization_id) AND
  (has_committee_access(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Public can view public organization meetings"
ON public.meetings FOR SELECT
USING (public_meeting = true);

-- Update Secretariat policies for meetings
DROP POLICY IF EXISTS "Secretariat accountable for scheduling meetings" ON public.meetings;
DROP POLICY IF EXISTS "Secretariat accountable for updating meetings" ON public.meetings;

CREATE POLICY "Secretariat accountable for scheduling meetings"
ON public.meetings FOR INSERT
WITH CHECK (
  can_access_organization(auth.uid(), organization_id) AND
  (is_committee_secretary(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role))
);

CREATE POLICY "Secretariat accountable for updating meetings"
ON public.meetings FOR UPDATE
USING (
  can_access_organization(auth.uid(), organization_id) AND
  (is_committee_secretary(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role))
);

-- Grant super_admin role to lucky.tshavhungwe@gmail.com
CREATE OR REPLACE FUNCTION public.grant_super_admin_to_email(_email TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _user_id UUID;
BEGIN
  SELECT user_id INTO _user_id FROM public.profiles WHERE email = _email LIMIT 1;
  
  IF _user_id IS NOT NULL THEN
    -- Check if role already exists
    IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = 'super_admin'::app_role) THEN
      INSERT INTO public.user_roles (user_id, role)
      VALUES (_user_id, 'super_admin'::app_role);
    END IF;
  END IF;
END;
$$;

-- Execute the function to grant super_admin
SELECT public.grant_super_admin_to_email('lucky.tshavhungwe@gmail.com');
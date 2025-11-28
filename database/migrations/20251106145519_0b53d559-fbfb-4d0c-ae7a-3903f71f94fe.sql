-- Departmental RBAC Implementation
-- Create function to get user's department from their profile
CREATE OR REPLACE FUNCTION public.get_user_department(_user_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT department 
  FROM public.profiles 
  WHERE user_id = _user_id
  LIMIT 1
$$;

-- Helper function to check if user can access department data
CREATE OR REPLACE FUNCTION public.can_access_department(_user_id uuid, _department text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    -- Admins and directors can access all departments
    has_role(_user_id, 'admin'::app_role) OR
    is_director(_user_id) OR
    -- Users can access their own department
    get_user_department(_user_id) = _department OR
    -- If department is NULL, allow access (for backwards compatibility)
    _department IS NULL
$$;

-- Update action_items RLS policies for departmental access
DROP POLICY IF EXISTS "Users can view relevant action items" ON public.action_items;
CREATE POLICY "Users can view relevant action items"
ON public.action_items
FOR SELECT
USING (
  (assigned_to_id = auth.uid()) OR 
  has_committee_access(auth.uid(), committee_id) OR 
  has_role(auth.uid(), 'admin'::app_role) OR
  can_access_department(auth.uid(), assigned_to_department)
);

DROP POLICY IF EXISTS "Users can update assigned action items" ON public.action_items;
CREATE POLICY "Users can update assigned action items"
ON public.action_items
FOR UPDATE
USING (
  (assigned_to_id = auth.uid()) OR 
  check_committee_leadership(auth.uid(), committee_id) OR 
  has_committee_role(auth.uid(), committee_id, 'secretary'::text) OR 
  has_role(auth.uid(), 'admin'::app_role) OR
  (can_access_department(auth.uid(), assigned_to_department) AND is_director(auth.uid()))
);

-- Update decisions_register RLS policies for departmental access
DROP POLICY IF EXISTS "Committee members can view decisions" ON public.decisions_register;
CREATE POLICY "Committee members can view decisions"
ON public.decisions_register
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = decisions_register.meeting_id
    AND (
      has_committee_access(auth.uid(), m.committee_id) OR 
      has_role(auth.uid(), 'admin'::app_role)
    )
  ) OR
  can_access_department(auth.uid(), owner_department)
);

DROP POLICY IF EXISTS "Decision owners can update their decisions" ON public.decisions_register;
CREATE POLICY "Decision owners can update their decisions"
ON public.decisions_register
FOR UPDATE
USING (
  auth.uid() = owner_id OR
  (can_access_department(auth.uid(), owner_department) AND is_director(auth.uid()))
);

-- Update departmental_registers RLS policies
DROP POLICY IF EXISTS "Admins and coordinators can view all registers" ON public.departmental_registers;
CREATE POLICY "Users can view departmental registers"
ON public.departmental_registers
FOR SELECT
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'coordinator'::app_role) OR
  can_access_department(auth.uid(), department)
);

DROP POLICY IF EXISTS "Secretariat responsible for register entries" ON public.departmental_registers;
CREATE POLICY "Authorized users can create register entries"
ON public.departmental_registers
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'clerk'::app_role) OR 
  has_role(auth.uid(), 'admin'::app_role) OR
  can_access_department(auth.uid(), department)
);

DROP POLICY IF EXISTS "Directors accountable for register tracking" ON public.departmental_registers;
CREATE POLICY "Authorized users can update registers"
ON public.departmental_registers
FOR UPDATE
USING (
  is_director(auth.uid()) OR 
  has_role(auth.uid(), 'admin'::app_role) OR
  can_access_department(auth.uid(), department)
);

-- Add comment documenting the departmental RBAC system
COMMENT ON FUNCTION get_user_department IS 'Returns the department of a user from their profile. Used for departmental RBAC.';
COMMENT ON FUNCTION can_access_department IS 'Checks if a user can access data from a specific department. Admins and directors have cross-department access, while regular users are limited to their own department.';
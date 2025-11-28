-- RACI-based access control implementation
-- A = Accountable (final authority), R = Responsible (does the work), C = Consulted, I = Informed

-- Helper function to check if user is a committee secretary/clerk
CREATE OR REPLACE FUNCTION public.is_committee_secretary(_user_id uuid, _committee_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT has_committee_role(_user_id, _committee_id, 'secretary') 
    OR has_role(_user_id, 'clerk');
$$;

-- Helper function to check if user is a director/MANCO member
CREATE OR REPLACE FUNCTION public.is_director(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT has_role(_user_id, 'coordinator') 
    OR has_role(_user_id, 'cfo');
$$;

-- Update meetings RLS policies for Planning & Scheduling (Secretariat is Accountable)
DROP POLICY IF EXISTS "Committee leadership can create meetings" ON public.meetings;
CREATE POLICY "Secretariat accountable for scheduling meetings"
ON public.meetings
FOR INSERT
TO authenticated
WITH CHECK (
  is_committee_secretary(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Committee leadership and secretary can update meetings" ON public.meetings;
CREATE POLICY "Secretariat accountable for updating meetings"
ON public.meetings
FOR UPDATE
TO authenticated
USING (
  is_committee_secretary(auth.uid(), committee_id)
  OR has_role(auth.uid(), 'admin')
);

-- Meeting packs RLS (Secretariat is Responsible for compilation)
DROP POLICY IF EXISTS "Committee leadership can manage meeting packs" ON public.meeting_packs;
CREATE POLICY "Secretariat responsible for pack compilation"
ON public.meeting_packs
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = meeting_packs.meeting_id
    AND (is_committee_secretary(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'))
  )
);

-- Session management RLS (Secretariat & Members Responsible, Chair Accountable)
DROP POLICY IF EXISTS "Committee leadership can manage sessions" ON public.meeting_sessions;
CREATE POLICY "Chair accountable for session management"
ON public.meeting_sessions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = meeting_sessions.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR is_committee_secretary(auth.uid(), m.committee_id)
      OR has_committee_access(auth.uid(), m.committee_id)
      OR has_role(auth.uid(), 'admin')
    )
  )
);

-- Decisions register RLS (Secretariat Responsible, Chair & Director Accountable)
DROP POLICY IF EXISTS "Committee leadership can manage decisions" ON public.decisions_register;
CREATE POLICY "Secretariat responsible for capturing decisions"
ON public.decisions_register
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = decisions_register.meeting_id
    AND (is_committee_secretary(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'))
  )
);

CREATE POLICY "Chair and Director accountable for decisions"
ON public.decisions_register
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = decisions_register.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR is_director(auth.uid())
      OR auth.uid() = decisions_register.owner_id
      OR has_role(auth.uid(), 'admin')
    )
  )
);

-- Minutes approval RLS (Secretariat Responsible, Chair & City Manager Accountable)
DROP POLICY IF EXISTS "Committee leadership can manage approval" ON public.minutes_approval;
CREATE POLICY "Secretariat responsible for minutes submission"
ON public.minutes_approval
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = minutes_approval.meeting_id
    AND (is_committee_secretary(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'))
  )
);

CREATE POLICY "Chair and City Manager accountable for approval"
ON public.minutes_approval
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = minutes_approval.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR has_role(auth.uid(), 'admin')
    )
  )
);

-- Documents publication (Secretariat Responsible, Records Management Accountable)
DROP POLICY IF EXISTS "Secretary and leadership can update documents" ON public.meeting_documents;
CREATE POLICY "Secretariat responsible for document updates"
ON public.meeting_documents
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND (
      is_committee_secretary(auth.uid(), m.committee_id)
      OR has_role(auth.uid(), 'admin')
      OR has_role(auth.uid(), 'clerk')
    )
  )
);

-- Departmental registers RLS (Secretariat Responsible, Director Accountable)
DROP POLICY IF EXISTS "Admins can manage registers" ON public.departmental_registers;
CREATE POLICY "Secretariat responsible for register entries"
ON public.departmental_registers
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'clerk')
  OR has_role(auth.uid(), 'admin')
);

CREATE POLICY "Directors accountable for register tracking"
ON public.departmental_registers
FOR UPDATE
TO authenticated
USING (
  is_director(auth.uid())
  OR has_role(auth.uid(), 'admin')
);

-- Action items RLS (Secretariat Responsible for creation)
DROP POLICY IF EXISTS "Leadership and secretary can create action items" ON public.action_items;
CREATE POLICY "Secretariat responsible for action items"
ON public.action_items
FOR INSERT
TO authenticated
WITH CHECK (
  is_committee_secretary(auth.uid(), committee_id)
  OR has_role(auth.uid(), 'admin')
);
-- Create function to check committee member role
CREATE OR REPLACE FUNCTION public.has_committee_role(_user_id uuid, _committee_id uuid, _role text)
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
      AND role = _role
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
  )
$$;

-- Drop and recreate meetings policies with segregation of duties
DROP POLICY IF EXISTS "Committee members and leadership can manage meetings" ON public.meetings;
DROP POLICY IF EXISTS "Users can view public meetings" ON public.meetings;

-- Only chairs and deputy chairs can schedule/create meetings
CREATE POLICY "Committee leadership can create meetings" 
ON public.meetings 
FOR INSERT 
WITH CHECK (
  check_committee_leadership(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Only chairs, deputy chairs, and secretaries can update meetings
CREATE POLICY "Committee leadership and secretary can update meetings" 
ON public.meetings 
FOR UPDATE 
USING (
  check_committee_leadership(auth.uid(), committee_id) 
  OR has_committee_role(auth.uid(), committee_id, 'secretary')
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Only admins and chairs can delete meetings
CREATE POLICY "Committee chairs and admins can delete meetings" 
ON public.meetings 
FOR DELETE 
USING (
  check_committee_leadership(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- All committee members can view their committee meetings
CREATE POLICY "Committee members can view committee meetings" 
ON public.meetings 
FOR SELECT 
USING (
  has_committee_access(auth.uid(), committee_id) 
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Public can view public meetings
CREATE POLICY "Public can view public meetings" 
ON public.meetings 
FOR SELECT 
USING (public_meeting = true);

-- Drop and recreate meeting documents policies with segregation
DROP POLICY IF EXISTS "Committee members can manage meeting documents" ON public.meeting_documents;
DROP POLICY IF EXISTS "Committee members can view all meeting documents" ON public.meeting_documents;
DROP POLICY IF EXISTS "Public can view published documents for public meetings" ON public.meeting_documents;

-- Only secretary and leadership can create documents
CREATE POLICY "Secretary and leadership can create documents" 
ON public.meeting_documents 
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR has_committee_role(auth.uid(), m.committee_id, 'secretary')
      OR has_role(auth.uid(), 'admin'::app_role)
    )
  )
);

-- Only secretary and leadership can update documents
CREATE POLICY "Secretary and leadership can update documents" 
ON public.meeting_documents 
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR has_committee_role(auth.uid(), m.committee_id, 'secretary')
      OR has_role(auth.uid(), 'admin'::app_role)
    )
  )
);

-- Only leadership can delete documents
CREATE POLICY "Committee leadership can delete documents" 
ON public.meeting_documents 
FOR DELETE 
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND (
      check_committee_leadership(auth.uid(), m.committee_id)
      OR has_role(auth.uid(), 'admin'::app_role)
    )
  )
);

-- Committee members can view their committee documents
CREATE POLICY "Committee members can view documents" 
ON public.meeting_documents 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND (
      has_committee_access(auth.uid(), m.committee_id)
      OR has_role(auth.uid(), 'admin'::app_role)
    )
  )
);

-- Public can view published documents for public meetings
CREATE POLICY "Public can view published public documents" 
ON public.meeting_documents 
FOR SELECT 
USING (
  published = true 
  AND EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_documents.meeting_id
    AND m.public_meeting = true
  )
);

-- Update action items policies for segregation
DROP POLICY IF EXISTS "Committee members can manage action items" ON public.action_items;
DROP POLICY IF EXISTS "Users can view relevant action items" ON public.action_items;

-- Only leadership and secretary can create action items
CREATE POLICY "Leadership and secretary can create action items" 
ON public.action_items 
FOR INSERT 
WITH CHECK (
  check_committee_leadership(auth.uid(), committee_id)
  OR has_committee_role(auth.uid(), committee_id, 'secretary')
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Assigned users can update their own action items, leadership can update all
CREATE POLICY "Users can update assigned action items" 
ON public.action_items 
FOR UPDATE 
USING (
  assigned_to_id = auth.uid()
  OR check_committee_leadership(auth.uid(), committee_id)
  OR has_committee_role(auth.uid(), committee_id, 'secretary')
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Only leadership can delete action items
CREATE POLICY "Leadership can delete action items" 
ON public.action_items 
FOR DELETE 
USING (
  check_committee_leadership(auth.uid(), committee_id)
  OR has_role(auth.uid(), 'admin'::app_role)
);

-- Users can view relevant action items
CREATE POLICY "Users can view relevant action items" 
ON public.action_items 
FOR SELECT 
USING (
  assigned_to_id = auth.uid()
  OR has_committee_access(auth.uid(), committee_id)
  OR has_role(auth.uid(), 'admin'::app_role)
);
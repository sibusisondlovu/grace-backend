-- Meeting Pack Compilation tracking
CREATE TABLE IF NOT EXISTS public.meeting_packs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL DEFAULT 1,
  pack_status TEXT NOT NULL DEFAULT 'draft',
  compiled_by UUID REFERENCES auth.users(id),
  compiled_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}',
  distribution_list TEXT[],
  restricted BOOLEAN DEFAULT false,
  signature_routing JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Session management details
CREATE TABLE IF NOT EXISTS public.meeting_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  session_start TIMESTAMP WITH TIME ZONE,
  session_end TIMESTAMP WITH TIME ZONE,
  declarations JSONB DEFAULT '[]',
  speakers_queue JSONB DEFAULT '[]',
  voting_config JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enhanced decisions/resolutions tracking with escalation
CREATE TABLE IF NOT EXISTS public.decisions_register (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  agenda_item_id UUID REFERENCES public.agenda_items(id),
  decision_number TEXT NOT NULL,
  decision_type TEXT NOT NULL,
  decision_text TEXT NOT NULL,
  owner_id UUID REFERENCES auth.users(id),
  owner_department TEXT,
  due_date DATE,
  priority TEXT DEFAULT 'medium',
  escalation_level TEXT DEFAULT 'manco',
  escalation_threshold JSONB,
  status TEXT NOT NULL DEFAULT 'pending',
  progress_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Minutes approval workflow
CREATE TABLE IF NOT EXISTS public.minutes_approval (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.meeting_documents(id),
  approval_stage TEXT NOT NULL DEFAULT 'draft',
  submitted_by UUID REFERENCES auth.users(id),
  submitted_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  comments TEXT,
  publication_scope TEXT DEFAULT 'internal',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Departmental registers and tracking
CREATE TABLE IF NOT EXISTS public.departmental_registers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  department TEXT NOT NULL,
  register_type TEXT NOT NULL,
  related_id UUID,
  related_table TEXT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  due_date DATE,
  completion_date DATE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on all new tables
ALTER TABLE public.meeting_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decisions_register ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.minutes_approval ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departmental_registers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for meeting_packs
CREATE POLICY "Committee members can view meeting packs"
  ON public.meeting_packs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = meeting_packs.meeting_id
      AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

CREATE POLICY "Committee leadership can manage meeting packs"
  ON public.meeting_packs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = meeting_packs.meeting_id
      AND (check_committee_leadership(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

-- RLS Policies for meeting_sessions
CREATE POLICY "Committee members can view sessions"
  ON public.meeting_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = meeting_sessions.meeting_id
      AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

CREATE POLICY "Committee leadership can manage sessions"
  ON public.meeting_sessions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = meeting_sessions.meeting_id
      AND (check_committee_leadership(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

-- RLS Policies for decisions_register
CREATE POLICY "Committee members can view decisions"
  ON public.decisions_register FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = decisions_register.meeting_id
      AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

CREATE POLICY "Committee leadership can manage decisions"
  ON public.decisions_register FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = decisions_register.meeting_id
      AND (check_committee_leadership(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

CREATE POLICY "Decision owners can update their decisions"
  ON public.decisions_register FOR UPDATE
  USING (auth.uid() = owner_id);

-- RLS Policies for minutes_approval
CREATE POLICY "Committee members can view approval status"
  ON public.minutes_approval FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = minutes_approval.meeting_id
      AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

CREATE POLICY "Committee leadership can manage approval"
  ON public.minutes_approval FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.meetings m
      WHERE m.id = minutes_approval.meeting_id
      AND (check_committee_leadership(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

-- RLS Policies for departmental_registers
CREATE POLICY "Admins and coordinators can view all registers"
  ON public.departmental_registers FOR SELECT
  USING (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'coordinator'::app_role)
  );

CREATE POLICY "Admins can manage registers"
  ON public.departmental_registers FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role));

-- Create indexes for performance
CREATE INDEX idx_meeting_packs_meeting ON public.meeting_packs(meeting_id);
CREATE INDEX idx_meeting_sessions_meeting ON public.meeting_sessions(meeting_id);
CREATE INDEX idx_decisions_register_meeting ON public.decisions_register(meeting_id);
CREATE INDEX idx_decisions_register_owner ON public.decisions_register(owner_id);
CREATE INDEX idx_minutes_approval_meeting ON public.minutes_approval(meeting_id);
CREATE INDEX idx_departmental_registers_dept ON public.departmental_registers(department);

-- Triggers for updated_at
CREATE TRIGGER update_meeting_packs_updated_at
  BEFORE UPDATE ON public.meeting_packs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_meeting_sessions_updated_at
  BEFORE UPDATE ON public.meeting_sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_decisions_register_updated_at
  BEFORE UPDATE ON public.decisions_register
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_minutes_approval_updated_at
  BEFORE UPDATE ON public.minutes_approval
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_departmental_registers_updated_at
  BEFORE UPDATE ON public.departmental_registers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
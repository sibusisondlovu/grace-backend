-- FR-014: Questions to Executive
CREATE TABLE IF NOT EXISTS public.questions_to_executive (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  committee_id UUID REFERENCES public.committees(id) ON DELETE CASCADE NOT NULL,
  councillor_id UUID NOT NULL,
  question_number TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('written', 'oral')),
  subject TEXT NOT NULL,
  question_text TEXT NOT NULL,
  addressed_to_dept TEXT NOT NULL,
  addressed_to_mmc TEXT,
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'routed', 'responded', 'tabled', 'overdue')),
  response_text TEXT,
  response_date TIMESTAMP WITH TIME ZONE,
  follow_up_required BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-019: Motion Management
CREATE TABLE IF NOT EXISTS public.motions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  committee_id UUID REFERENCES public.committees(id) ON DELETE CASCADE NOT NULL,
  motion_number TEXT NOT NULL,
  motion_type TEXT NOT NULL CHECK (motion_type IN ('substantive', 'procedural', 'amendment')),
  submitter_id UUID NOT NULL,
  seconder_id UUID,
  notice_date DATE NOT NULL,
  title TEXT NOT NULL,
  motion_text TEXT NOT NULL,
  admissibility_status TEXT NOT NULL DEFAULT 'pending' CHECK (admissibility_status IN ('pending', 'admissible', 'inadmissible')),
  admissibility_notes TEXT,
  scheduled_meeting_id UUID REFERENCES public.meetings(id) ON DELETE SET NULL,
  outcome TEXT CHECK (outcome IN ('adopted', 'rejected', 'withdrawn', 'referred', 'amended')),
  outcome_notes TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'scheduled', 'debated', 'closed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-020: Petitions Workflow
CREATE TABLE IF NOT EXISTS public.petitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  petition_number TEXT NOT NULL,
  petition_type TEXT NOT NULL CHECK (petition_type IN ('individual', 'collective', 'organization')),
  submitter_name TEXT NOT NULL,
  submitter_contact TEXT,
  subject TEXT NOT NULL,
  petition_text TEXT NOT NULL,
  signatures_count INTEGER DEFAULT 1,
  date_received DATE NOT NULL DEFAULT CURRENT_DATE,
  classification TEXT NOT NULL CHECK (classification IN ('service_delivery', 'policy', 'by_law', 'complaint', 'other')),
  routed_to_committee_id UUID REFERENCES public.committees(id) ON DELETE SET NULL,
  routed_to_dept TEXT,
  linked_agenda_item_id UUID REFERENCES public.agenda_items(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'under_review', 'routed', 'scheduled', 'responded', 'closed')),
  response_text TEXT,
  response_date DATE,
  petitioner_notified_date DATE,
  publication_status TEXT NOT NULL DEFAULT 'private' CHECK (publication_status IN ('private', 'public', 'redacted')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-017: Summons/RFI Register
CREATE TABLE IF NOT EXISTS public.information_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number TEXT NOT NULL,
  request_type TEXT NOT NULL CHECK (request_type IN ('rfi', 'summons', 'subpoena')),
  committee_id UUID REFERENCES public.committees(id) ON DELETE CASCADE NOT NULL,
  issued_by_id UUID NOT NULL,
  addressed_to TEXT NOT NULL,
  addressed_to_dept TEXT,
  subject TEXT NOT NULL,
  request_details TEXT NOT NULL,
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  deadline_date DATE NOT NULL,
  compliance_status TEXT NOT NULL DEFAULT 'pending' CHECK (compliance_status IN ('pending', 'acknowledged', 'partial', 'complied', 'overdue', 'escalated')),
  response_received_date DATE,
  response_summary TEXT,
  linked_meeting_id UUID REFERENCES public.meetings(id) ON DELETE SET NULL,
  escalation_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-022: Ward Committee Inputs
CREATE TABLE IF NOT EXISTS public.ward_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ward_number TEXT NOT NULL,
  submission_number TEXT NOT NULL,
  submission_type TEXT NOT NULL CHECK (submission_type IN ('concern', 'proposal', 'feedback', 'complaint')),
  topic TEXT NOT NULL,
  description TEXT NOT NULL,
  submitter_details TEXT,
  date_submitted DATE NOT NULL DEFAULT CURRENT_DATE,
  linked_committee_id UUID REFERENCES public.committees(id) ON DELETE SET NULL,
  linked_agenda_item_id UUID REFERENCES public.agenda_items(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'under_review', 'linked', 'actioned', 'feedback_sent')),
  feedback_text TEXT,
  feedback_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-023: PAIA Requests
CREATE TABLE IF NOT EXISTS public.paia_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number TEXT NOT NULL,
  requester_name TEXT NOT NULL,
  requester_contact TEXT NOT NULL,
  requester_address TEXT,
  record_description TEXT NOT NULL,
  form_of_access TEXT NOT NULL CHECK (form_of_access IN ('inspection', 'copy', 'digital')),
  date_received DATE NOT NULL DEFAULT CURRENT_DATE,
  statutory_deadline DATE NOT NULL,
  extension_granted BOOLEAN DEFAULT false,
  extended_deadline DATE,
  decision TEXT CHECK (decision IN ('granted', 'partial', 'refused', 'transferred')),
  decision_date DATE,
  refusal_grounds TEXT,
  fees_prescribed DECIMAL(10,2),
  fees_paid BOOLEAN DEFAULT false,
  release_package_ref TEXT,
  appeal_lodged BOOLEAN DEFAULT false,
  appeal_notes TEXT,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'under_assessment', 'awaiting_payment', 'processing', 'decided', 'released', 'appealed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-015: MPAC UIFW Casework
CREATE TABLE IF NOT EXISTS public.uifw_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_number TEXT NOT NULL,
  case_type TEXT NOT NULL CHECK (case_type IN ('unauthorized_expenditure', 'irregular_expenditure', 'fruitless_wasteful')),
  financial_year TEXT NOT NULL,
  department TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  description TEXT NOT NULL,
  date_opened DATE NOT NULL DEFAULT CURRENT_DATE,
  hearing_scheduled_meeting_id UUID REFERENCES public.meetings(id) ON DELETE SET NULL,
  hearing_date DATE,
  evidence_summary TEXT,
  findings TEXT,
  recommendations TEXT,
  council_decision TEXT,
  council_decision_date DATE,
  implementation_status TEXT CHECK (implementation_status IN ('pending', 'in_progress', 'implemented', 'not_implemented')),
  closure_report TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'hearing_scheduled', 'hearing_complete', 'council_referred', 'closed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-018: Site Visit/Oversight
CREATE TABLE IF NOT EXISTS public.site_visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visit_number TEXT NOT NULL,
  committee_id UUID REFERENCES public.committees(id) ON DELETE CASCADE NOT NULL,
  site_location TEXT NOT NULL,
  site_address TEXT,
  visit_date DATE NOT NULL,
  visit_purpose TEXT NOT NULL,
  participants TEXT[] NOT NULL,
  observations TEXT,
  evidence_collected TEXT[],
  findings TEXT,
  linked_resolution_id UUID REFERENCES public.action_items(id) ON DELETE SET NULL,
  linked_agenda_item_id UUID REFERENCES public.agenda_items(id) ON DELETE SET NULL,
  report_drafted BOOLEAN DEFAULT false,
  report_text TEXT,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'conducted', 'report_pending', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- FR-024: POPIA Publication Controls
CREATE TABLE IF NOT EXISTS public.document_popia_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES public.meeting_documents(id) ON DELETE CASCADE NOT NULL,
  personal_info_category TEXT NOT NULL CHECK (personal_info_category IN ('name', 'contact', 'financial', 'health', 'biometric', 'political', 'other')),
  lawful_basis TEXT NOT NULL CHECK (lawful_basis IN ('consent', 'legal_obligation', 'public_interest', 'legitimate_interest')),
  redaction_required BOOLEAN DEFAULT false,
  redaction_notes TEXT,
  audit_log JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on all new tables
ALTER TABLE public.questions_to_executive ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.petitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.information_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ward_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paia_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uifw_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_popia_tags ENABLE ROW LEVEL SECURITY;

-- Add updated_at triggers
CREATE TRIGGER update_questions_to_executive_updated_at BEFORE UPDATE ON public.questions_to_executive
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_motions_updated_at BEFORE UPDATE ON public.motions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_petitions_updated_at BEFORE UPDATE ON public.petitions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_information_requests_updated_at BEFORE UPDATE ON public.information_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_ward_submissions_updated_at BEFORE UPDATE ON public.ward_submissions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_paia_requests_updated_at BEFORE UPDATE ON public.paia_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_uifw_cases_updated_at BEFORE UPDATE ON public.uifw_cases
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_site_visits_updated_at BEFORE UPDATE ON public.site_visits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_document_popia_tags_updated_at BEFORE UPDATE ON public.document_popia_tags
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS Policies for Questions to Executive
CREATE POLICY "Committee members can view questions" ON public.questions_to_executive
  FOR SELECT USING (
    has_committee_access(auth.uid(), committee_id) OR 
    has_role(auth.uid(), 'admin'::app_role) OR
    councillor_id = auth.uid()
  );

CREATE POLICY "Committee members can create questions" ON public.questions_to_executive
  FOR INSERT WITH CHECK (
    (has_committee_access(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)) AND
    councillor_id = auth.uid()
  );

CREATE POLICY "Admins and authors can update questions" ON public.questions_to_executive
  FOR UPDATE USING (
    has_role(auth.uid(), 'admin'::app_role) OR
    councillor_id = auth.uid()
  );

-- RLS Policies for Motions
CREATE POLICY "Committee members can view motions" ON public.motions
  FOR SELECT USING (
    has_committee_access(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Committee members can create motions" ON public.motions
  FOR INSERT WITH CHECK (
    has_committee_access(auth.uid(), committee_id) AND
    submitter_id = auth.uid()
  );

CREATE POLICY "Admins and authors can update motions" ON public.motions
  FOR UPDATE USING (
    has_role(auth.uid(), 'admin'::app_role) OR
    submitter_id = auth.uid()
  );

-- RLS Policies for Petitions
CREATE POLICY "Public can view published petitions" ON public.petitions
  FOR SELECT USING (publication_status = 'public' OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins can manage petitions" ON public.petitions
  FOR ALL USING (has_role(auth.uid(), 'admin'::app_role));

-- RLS Policies for Information Requests
CREATE POLICY "Committee members can view information requests" ON public.information_requests
  FOR SELECT USING (
    has_committee_access(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Committee leadership can create information requests" ON public.information_requests
  FOR INSERT WITH CHECK (
    check_committee_leadership(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Admins can update information requests" ON public.information_requests
  FOR UPDATE USING (has_role(auth.uid(), 'admin'::app_role));

-- RLS Policies for Ward Submissions
CREATE POLICY "Committee members can view ward submissions" ON public.ward_submissions
  FOR SELECT USING (
    linked_committee_id IS NULL OR
    has_committee_access(auth.uid(), linked_committee_id) OR 
    has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Anyone can create ward submissions" ON public.ward_submissions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can update ward submissions" ON public.ward_submissions
  FOR UPDATE USING (has_role(auth.uid(), 'admin'::app_role));

-- RLS Policies for PAIA Requests
CREATE POLICY "Admins can manage PAIA requests" ON public.paia_requests
  FOR ALL USING (has_role(auth.uid(), 'admin'::app_role));

-- RLS Policies for UIFW Cases
CREATE POLICY "MPAC members can view UIFW cases" ON public.uifw_cases
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.committees c
      WHERE c.type = 'MPAC' AND has_committee_access(auth.uid(), c.id)
    ) OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "MPAC members can manage UIFW cases" ON public.uifw_cases
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.committees c
      WHERE c.type = 'MPAC' AND check_committee_leadership(auth.uid(), c.id)
    ) OR has_role(auth.uid(), 'admin'::app_role)
  );

-- RLS Policies for Site Visits
CREATE POLICY "Committee members can view site visits" ON public.site_visits
  FOR SELECT USING (
    has_committee_access(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Committee leadership can manage site visits" ON public.site_visits
  FOR ALL USING (
    check_committee_leadership(auth.uid(), committee_id) OR has_role(auth.uid(), 'admin'::app_role)
  );

-- RLS Policies for POPIA Tags
CREATE POLICY "Admins can manage POPIA tags" ON public.document_popia_tags
  FOR ALL USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Committee members can view POPIA tags" ON public.document_popia_tags
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.meeting_documents md
      JOIN public.meetings m ON md.meeting_id = m.id
      WHERE md.id = document_popia_tags.document_id
      AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
    )
  );

-- Create indexes for performance
CREATE INDEX idx_questions_committee ON public.questions_to_executive(committee_id);
CREATE INDEX idx_questions_status ON public.questions_to_executive(status);
CREATE INDEX idx_motions_committee ON public.motions(committee_id);
CREATE INDEX idx_petitions_status ON public.petitions(status);
CREATE INDEX idx_info_requests_committee ON public.information_requests(committee_id);
CREATE INDEX idx_ward_submissions_committee ON public.ward_submissions(linked_committee_id);
CREATE INDEX idx_paia_status ON public.paia_requests(status);
CREATE INDEX idx_uifw_status ON public.uifw_cases(status);
CREATE INDEX idx_site_visits_committee ON public.site_visits(committee_id);
-- Create business processes table
CREATE TABLE public.business_processes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  icon TEXT,
  overall_progress INTEGER DEFAULT 0,
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'blocked')),
  department TEXT,
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Create process steps table
CREATE TABLE public.process_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  process_id UUID REFERENCES public.business_processes(id) ON DELETE CASCADE NOT NULL,
  step_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')),
  responsible_party TEXT,
  duration_days INTEGER,
  dependencies TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.business_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_steps ENABLE ROW LEVEL SECURITY;

-- RLS Policies for business_processes
CREATE POLICY "Anyone can view business processes"
  ON public.business_processes
  FOR SELECT
  USING (true);

CREATE POLICY "Admins and coordinators can manage processes"
  ON public.business_processes
  FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role));

-- RLS Policies for process_steps
CREATE POLICY "Anyone can view process steps"
  ON public.process_steps
  FOR SELECT
  USING (true);

CREATE POLICY "Admins and coordinators can manage steps"
  ON public.process_steps
  FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role));

-- Create trigger for updated_at
CREATE TRIGGER update_business_processes_updated_at
  BEFORE UPDATE ON public.business_processes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_process_steps_updated_at
  BEFORE UPDATE ON public.process_steps
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert sample processes
INSERT INTO public.business_processes (name, description, category, icon, overall_progress, status, department) VALUES
('Budget Preparation', 'Annual budget compilation and submission', 'Financial', 'DollarSign', 65, 'in_progress', 'Finance'),
('Performance Management', 'Quarterly performance review cycle', 'HR', 'Target', 40, 'in_progress', 'Human Resources'),
('Procurement Process', 'Standard procurement and tender process', 'Supply Chain', 'ShoppingCart', 80, 'in_progress', 'Supply Chain'),
('Audit Compliance', 'Internal and external audit readiness', 'Governance', 'Shield', 55, 'in_progress', 'Internal Audit');
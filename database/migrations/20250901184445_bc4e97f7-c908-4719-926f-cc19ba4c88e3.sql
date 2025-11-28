-- Enable RLS on auth.users (already enabled by Supabase)
-- Create user profiles table
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  job_title TEXT,
  department TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create user roles enum and table
CREATE TYPE public.app_role as enum ('admin', 'speaker', 'chair', 'deputy_chair', 'whip', 'member', 'external_member', 'coordinator', 'clerk', 'legal', 'cfo', 'public');

CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  committee_id UUID NULL, -- Role can be committee-specific
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, role, committee_id)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create committees table
CREATE TABLE public.committees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'council', 'section79', 'section80', 'mpac', 'audit', 'ward', 'mpt', 'adhoc'
  description TEXT,
  terms_of_reference TEXT,
  quorum_percentage INTEGER DEFAULT 50,
  notice_period_days INTEGER DEFAULT 5,
  chair_id UUID REFERENCES auth.users(id),
  deputy_chair_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'active', -- 'active', 'inactive', 'dissolved'
  public_access_allowed BOOLEAN DEFAULT true,
  virtual_meetings_allowed BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.committees ENABLE ROW LEVEL SECURITY;

-- Create committee members table
CREATE TABLE public.committee_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  committee_id UUID NOT NULL REFERENCES public.committees(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'chair', 'deputy_chair', 'member', 'alternate', 'external'
  party_affiliation TEXT,
  ward_number TEXT,
  voting_rights BOOLEAN DEFAULT true,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (committee_id, user_id)
);

ALTER TABLE public.committee_members ENABLE ROW LEVEL SECURITY;

-- Create meetings table
CREATE TABLE public.meetings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  committee_id UUID NOT NULL REFERENCES public.committees(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
  venue TEXT,
  meeting_type TEXT DEFAULT 'physical', -- 'physical', 'virtual', 'hybrid'
  livestream_url TEXT,
  recording_url TEXT,
  status TEXT DEFAULT 'scheduled', -- 'scheduled', 'in_progress', 'completed', 'cancelled', 'postponed'
  agenda_published BOOLEAN DEFAULT false,
  minutes_published BOOLEAN DEFAULT false,
  public_meeting BOOLEAN DEFAULT true,
  quorum_achieved BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;

-- Create agenda items table
CREATE TABLE public.agenda_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  item_number TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  sponsor_id UUID REFERENCES auth.users(id),
  item_type TEXT DEFAULT 'report', -- 'report', 'motion', 'question', 'petition', 'confidential'
  classification TEXT DEFAULT 'open', -- 'open', 'confidential', 'in_committee'
  status TEXT DEFAULT 'draft', -- 'draft', 'submitted', 'reviewed', 'approved', 'published'
  estimated_duration INTEGER, -- minutes
  order_index INTEGER,
  late_item BOOLEAN DEFAULT false,
  requires_vote BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;

-- Create action items table
CREATE TABLE public.action_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID REFERENCES public.meetings(id),
  agenda_item_id UUID REFERENCES public.agenda_items(id),
  title TEXT NOT NULL,
  description TEXT,
  assigned_to_id UUID REFERENCES auth.users(id),
  assigned_to_department TEXT,
  due_date DATE,
  priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'overdue', 'escalated'
  committee_id UUID REFERENCES public.committees(id),
  resolution_text TEXT,
  outcome TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.action_items ENABLE ROW LEVEL SECURITY;

-- Create attendance table
CREATE TABLE public.meeting_attendance (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attendance_status TEXT NOT NULL, -- 'present', 'absent', 'apology', 'late_arrival', 'early_departure'
  arrival_time TIMESTAMP WITH TIME ZONE,
  departure_time TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (meeting_id, user_id)
);

ALTER TABLE public.meeting_attendance ENABLE ROW LEVEL SECURITY;

-- Create function to check user roles
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Create function to check committee access
CREATE OR REPLACE FUNCTION public.has_committee_access(_user_id uuid, _committee_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.committee_members
    WHERE user_id = _user_id
      AND committee_id = _committee_id
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
  ) OR public.has_role(_user_id, 'admin')
$$;

-- Create profile auto-creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY definer SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, first_name, last_name, email)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    new.email
  );
  RETURN new;
END;
$$;

-- Create trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create update function for updated_at timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_committees_updated_at
  BEFORE UPDATE ON public.committees
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_meetings_updated_at
  BEFORE UPDATE ON public.meetings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agenda_items_updated_at
  BEFORE UPDATE ON public.agenda_items
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_action_items_updated_at
  BEFORE UPDATE ON public.action_items
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for user_roles
CREATE POLICY "Users can view all roles" ON public.user_roles
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage roles" ON public.user_roles
  FOR ALL USING (public.has_role(auth.uid(), 'admin'));

-- RLS Policies for committees
CREATE POLICY "Users can view all committees" ON public.committees
  FOR SELECT USING (true);

CREATE POLICY "Admins and chairs can manage committees" ON public.committees
  FOR ALL USING (
    public.has_role(auth.uid(), 'admin') OR 
    chair_id = auth.uid() OR 
    deputy_chair_id = auth.uid()
  );

-- RLS Policies for committee_members
CREATE POLICY "Users can view all committee members" ON public.committee_members
  FOR SELECT USING (true);

CREATE POLICY "Admins and chairs can manage committee members" ON public.committee_members
  FOR ALL USING (
    public.has_role(auth.uid(), 'admin') OR 
    EXISTS (
      SELECT 1 FROM public.committees 
      WHERE id = committee_id 
      AND (chair_id = auth.uid() OR deputy_chair_id = auth.uid())
    )
  );

-- RLS Policies for meetings
CREATE POLICY "Users can view public meetings" ON public.meetings
  FOR SELECT USING (
    public_meeting = true OR 
    public.has_committee_access(auth.uid(), committee_id) OR
    public.has_role(auth.uid(), 'admin')
  );

CREATE POLICY "Committee members can manage meetings" ON public.meetings
  FOR ALL USING (
    public.has_committee_access(auth.uid(), committee_id) OR
    public.has_role(auth.uid(), 'admin')
  );

-- RLS Policies for agenda_items
CREATE POLICY "Users can view open agenda items" ON public.agenda_items
  FOR SELECT USING (
    classification = 'open' OR 
    EXISTS (
      SELECT 1 FROM public.meetings m 
      WHERE m.id = meeting_id 
      AND (public.has_committee_access(auth.uid(), m.committee_id) OR public.has_role(auth.uid(), 'admin'))
    )
  );

CREATE POLICY "Committee members can manage agenda items" ON public.agenda_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.meetings m 
      WHERE m.id = meeting_id 
      AND (public.has_committee_access(auth.uid(), m.committee_id) OR public.has_role(auth.uid(), 'admin'))
    )
  );

-- RLS Policies for action_items
CREATE POLICY "Users can view relevant action items" ON public.action_items
  FOR SELECT USING (
    assigned_to_id = auth.uid() OR
    public.has_committee_access(auth.uid(), committee_id) OR
    public.has_role(auth.uid(), 'admin')
  );

CREATE POLICY "Committee members can manage action items" ON public.action_items
  FOR ALL USING (
    public.has_committee_access(auth.uid(), committee_id) OR
    public.has_role(auth.uid(), 'admin') OR
    assigned_to_id = auth.uid()
  );

-- RLS Policies for meeting_attendance
CREATE POLICY "Users can view meeting attendance" ON public.meeting_attendance
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.meetings m 
      WHERE m.id = meeting_id 
      AND (public.has_committee_access(auth.uid(), m.committee_id) OR public.has_role(auth.uid(), 'admin'))
    )
  );

CREATE POLICY "Committee members can manage attendance" ON public.meeting_attendance
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.meetings m 
      WHERE m.id = meeting_id 
      AND (public.has_committee_access(auth.uid(), m.committee_id) OR public.has_role(auth.uid(), 'admin'))
    )
  );
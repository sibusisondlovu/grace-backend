-- Create users table (replacing Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  job_title TEXT,
  department TEXT,
  avatar_url TEXT,
  organization_id UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user roles enum and table
DO $$ BEGIN
  CREATE TYPE app_role as enum ('admin', 'speaker', 'chair', 'deputy_chair', 'whip', 'member', 'external_member', 'coordinator', 'clerk', 'legal', 'cfo', 'public', 'super_admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  committee_id UUID NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, role, committee_id)
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  domain TEXT UNIQUE,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#0EA5E9',
  secondary_color TEXT DEFAULT '#F59E0B',
  contact_email TEXT,
  contact_phone TEXT,
  address TEXT,
  teams_webhook_url TEXT,
  is_active BOOLEAN DEFAULT true,
  subscription_status TEXT DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'suspended', 'cancelled')),
  subscription_tier TEXT DEFAULT 'standard' CHECK (subscription_tier IN ('standard', 'premium', 'enterprise')),
  trial_ends_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create committees table
CREATE TABLE IF NOT EXISTS committees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT,
  terms_of_reference TEXT,
  quorum_percentage INTEGER DEFAULT 50,
  notice_period_days INTEGER DEFAULT 5,
  chair_id UUID REFERENCES users(id),
  deputy_chair_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'active',
  public_access_allowed BOOLEAN DEFAULT true,
  virtual_meetings_allowed BOOLEAN DEFAULT true,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create committee members table
CREATE TABLE IF NOT EXISTS committee_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  committee_id UUID NOT NULL REFERENCES committees(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  party_affiliation TEXT,
  ward_number TEXT,
  voting_rights BOOLEAN DEFAULT true,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (committee_id, user_id)
);

-- Create meetings table
CREATE TABLE IF NOT EXISTS meetings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  committee_id UUID NOT NULL REFERENCES committees(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
  venue TEXT,
  meeting_type TEXT DEFAULT 'physical',
  livestream_url TEXT,
  recording_url TEXT,
  status TEXT DEFAULT 'scheduled',
  agenda_published BOOLEAN DEFAULT false,
  minutes_published BOOLEAN DEFAULT false,
  public_meeting BOOLEAN DEFAULT true,
  quorum_achieved BOOLEAN,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create agenda items table
CREATE TABLE IF NOT EXISTS agenda_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  item_number TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  sponsor_id UUID REFERENCES users(id),
  item_type TEXT DEFAULT 'report',
  classification TEXT DEFAULT 'open',
  status TEXT DEFAULT 'draft',
  estimated_duration INTEGER,
  order_index INTEGER,
  late_item BOOLEAN DEFAULT false,
  requires_vote BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create action items table
CREATE TABLE IF NOT EXISTS action_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID REFERENCES meetings(id),
  agenda_item_id UUID REFERENCES agenda_items(id),
  title TEXT NOT NULL,
  description TEXT,
  assigned_to_id UUID REFERENCES users(id),
  assigned_to_department TEXT,
  due_date DATE,
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'pending',
  committee_id UUID REFERENCES committees(id),
  resolution_text TEXT,
  outcome TEXT,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create attendance table
CREATE TABLE IF NOT EXISTS meeting_attendance (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attendance_status TEXT NOT NULL,
  arrival_time TIMESTAMP WITH TIME ZONE,
  departure_time TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (meeting_id, user_id)
);

-- Create email_notifications table
CREATE TABLE IF NOT EXISTS email_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  recipient_email TEXT NOT NULL,
  recipient_id UUID REFERENCES users(id),
  subject TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  metadata JSONB,
  status TEXT DEFAULT 'logged',
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create teams_notifications table
CREATE TABLE IF NOT EXISTS teams_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  success BOOLEAN DEFAULT false,
  error_message TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create update function for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_committees_updated_at ON committees;
CREATE TRIGGER update_committees_updated_at
  BEFORE UPDATE ON committees
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_meetings_updated_at ON meetings;
CREATE TRIGGER update_meetings_updated_at
  BEFORE UPDATE ON meetings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_agenda_items_updated_at ON agenda_items;
CREATE TRIGGER update_agenda_items_updated_at
  BEFORE UPDATE ON agenda_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_action_items_updated_at ON action_items;
CREATE TRIGGER update_action_items_updated_at
  BEFORE UPDATE ON action_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  changes JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

-- Create City of Johannesburg as first organization
INSERT INTO organizations (
  id,
  name,
  slug,
  contact_email,
  primary_color,
  secondary_color,
  subscription_status,
  subscription_tier
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'City of Johannesburg',
  'city-of-johannesburg',
  'info@joburg.org.za',
  '#0EA5E9',
  '#F59E0B',
  'active',
  'enterprise'
)
ON CONFLICT (id) DO NOTHING;


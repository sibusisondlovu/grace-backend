-- Multi-tenancy Part 1: Schema and enum setup

-- Update app_role enum to include super_admin
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid WHERE t.typname = 'app_role' AND e.enumlabel = 'super_admin') THEN
    ALTER TYPE app_role ADD VALUE 'super_admin';
  END IF;
END $$;

-- Create organizations table (municipalities)
CREATE TABLE IF NOT EXISTS public.organizations (
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
  is_active BOOLEAN DEFAULT true,
  subscription_status TEXT DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'suspended', 'cancelled')),
  subscription_tier TEXT DEFAULT 'standard' CHECK (subscription_tier IN ('standard', 'premium', 'enterprise')),
  trial_ends_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  tier TEXT NOT NULL CHECK (tier IN ('standard', 'premium', 'enterprise')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled', 'past_due')),
  monthly_price NUMERIC(10, 2) NOT NULL,
  billing_cycle_start DATE NOT NULL,
  billing_cycle_end DATE NOT NULL,
  max_users INTEGER,
  max_committees INTEGER,
  features JSONB DEFAULT '{}',
  payment_method TEXT,
  last_payment_date TIMESTAMP WITH TIME ZONE,
  next_payment_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add organization_id to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Add organization_id to all relevant tables
ALTER TABLE public.committees ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.action_items ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.petitions ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.paia_requests ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.motions ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.questions_to_executive ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.site_visits ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.uifw_cases ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.reports_library ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.business_processes ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.departmental_registers ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Create City of Johannesburg as first organization
INSERT INTO public.organizations (
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

-- Migrate existing data to City of Johannesburg
UPDATE public.profiles SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.committees SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.meetings SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.action_items SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.petitions SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.paia_requests SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.motions SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.questions_to_executive SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.site_visits SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.uifw_cases SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.reports_library SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.business_processes SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;
UPDATE public.departmental_registers SET organization_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE organization_id IS NULL;

-- Make organization_id NOT NULL after migration for critical tables
ALTER TABLE public.profiles ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE public.committees ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE public.meetings ALTER COLUMN organization_id SET NOT NULL;

-- Create triggers for updated_at
CREATE TRIGGER update_organizations_updated_at
BEFORE UPDATE ON public.organizations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON public.subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
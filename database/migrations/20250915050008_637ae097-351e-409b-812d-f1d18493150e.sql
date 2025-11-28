-- Insert admin role for the first user to enable meeting creation
INSERT INTO public.user_roles (user_id, role)
SELECT user_id, 'admin'::app_role
FROM public.profiles 
LIMIT 1
ON CONFLICT (user_id, role) DO NOTHING;

-- Add committee memberships for all users to all committees to enable meeting management
INSERT INTO public.committee_members (user_id, committee_id, role, voting_rights)
SELECT p.user_id, c.id, 'chair', true
FROM public.profiles p
CROSS JOIN public.committees c
ON CONFLICT DO NOTHING;

-- Update committees to set chairs
UPDATE public.committees 
SET chair_id = (SELECT user_id FROM public.profiles LIMIT 1)
WHERE chair_id IS NULL;
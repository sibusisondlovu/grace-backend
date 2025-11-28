-- Insert admin role for the first user to enable meeting creation
INSERT INTO public.user_roles (user_id, role)
SELECT user_id, 'admin'::app_role
FROM public.profiles 
LIMIT 1
WHERE NOT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = profiles.user_id AND role = 'admin'::app_role
);

-- Add committee memberships for all users to all committees to enable meeting management
INSERT INTO public.committee_members (user_id, committee_id, role, voting_rights)
SELECT p.user_id, c.id, 'chair', true
FROM public.profiles p
CROSS JOIN public.committees c
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_members cm 
    WHERE cm.user_id = p.user_id AND cm.committee_id = c.id
);

-- Update committees to set chairs where not already set
UPDATE public.committees 
SET chair_id = (SELECT user_id FROM public.profiles LIMIT 1)
WHERE chair_id IS NULL;
-- Helper function to assign admin role to first user in an organization
CREATE OR REPLACE FUNCTION public.assign_admin_role_if_first_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  user_count INTEGER;
  org_id UUID;
BEGIN
  -- Get the organization_id for this user
  SELECT organization_id INTO org_id
  FROM public.profiles
  WHERE user_id = NEW.id
  LIMIT 1;
  
  -- Count existing users in this organization (excluding the new user)
  SELECT COUNT(*) INTO user_count
  FROM public.profiles
  WHERE organization_id = org_id
    AND user_id != NEW.id;
  
  -- If this is the first user in the organization, make them an admin
  IF user_count = 0 THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin'::app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
    
    RAISE NOTICE 'Assigned admin role to first user % in organization %', NEW.id, org_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-assign admin to first user
DROP TRIGGER IF EXISTS assign_admin_on_first_user ON auth.users;
CREATE TRIGGER assign_admin_on_first_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.assign_admin_role_if_first_user();

-- Function to help onboarding: create organization and assign admin
CREATE OR REPLACE FUNCTION public.complete_user_onboarding(
  _user_id UUID,
  _organization_name TEXT,
  _organization_domain TEXT,
  _first_name TEXT,
  _last_name TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  _org_id UUID;
  _profile_id UUID;
  result JSON;
BEGIN
  -- Create organization
  INSERT INTO public.organizations (name, domain, is_active)
  VALUES (_organization_name, _organization_domain, true)
  RETURNING id INTO _org_id;
  
  -- Update user profile with organization
  UPDATE public.profiles
  SET 
    organization_id = _org_id,
    first_name = _first_name,
    last_name = _last_name,
    updated_at = NOW()
  WHERE user_id = _user_id
  RETURNING id INTO _profile_id;
  
  -- Assign admin role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (_user_id, 'admin'::app_role)
  ON CONFLICT (user_id, role) DO NOTHING;
  
  -- Return success with org details
  result := json_build_object(
    'success', true,
    'organization_id', _org_id,
    'profile_id', _profile_id,
    'message', 'Onboarding completed successfully'
  );
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;
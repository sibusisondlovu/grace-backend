-- Grant admin role to the current user (lucky.tshavhungwe@gmail.com)
DO $$
DECLARE
  admin_user_id uuid;
  existing_role_count integer;
BEGIN
  -- Get the user_id for the email
  SELECT id INTO admin_user_id
  FROM auth.users
  WHERE email = 'lucky.tshavhungwe@gmail.com';

  -- Only insert if user exists
  IF admin_user_id IS NOT NULL THEN
    -- Check if role already exists
    SELECT COUNT(*) INTO existing_role_count
    FROM public.user_roles
    WHERE user_id = admin_user_id AND role = 'admin';
    
    -- Insert only if doesn't exist
    IF existing_role_count = 0 THEN
      INSERT INTO public.user_roles (user_id, role)
      VALUES (admin_user_id, 'admin');
      RAISE NOTICE 'Admin role granted to user: %', admin_user_id;
    ELSE
      RAISE NOTICE 'User already has admin role: %', admin_user_id;
    END IF;
  ELSE
    RAISE NOTICE 'User not found with email: lucky.tshavhungwe@gmail.com';
  END IF;
END $$;
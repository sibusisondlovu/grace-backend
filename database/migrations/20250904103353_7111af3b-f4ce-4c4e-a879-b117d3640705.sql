-- Fix security vulnerability: Remove overly permissive profile viewing policy
-- and replace with more restrictive access controls

-- First, drop the problematic policy that allows any authenticated user to view other profiles
DROP POLICY IF EXISTS "Authenticated users can view basic profile info" ON public.profiles;

-- Create a more secure policy that only allows admins to view other users' profiles
-- This ensures only authorized personnel can access other users' information
CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (
  auth.uid() = user_id OR 
  has_role(auth.uid(), 'admin'::app_role)
);

-- Optional: If committee members need to see basic info of other committee members,
-- we can add a more restrictive policy (commented out for now - enable if needed)
/*
CREATE POLICY "Committee members can view basic info of fellow members" 
ON public.profiles 
FOR SELECT 
USING (
  auth.uid() = user_id OR 
  has_role(auth.uid(), 'admin'::app_role) OR
  EXISTS (
    SELECT 1 FROM public.committee_members cm1
    JOIN public.committee_members cm2 ON cm1.committee_id = cm2.committee_id
    WHERE cm1.user_id = auth.uid() 
    AND cm2.user_id = profiles.user_id
    AND cm1.end_date IS NULL 
    AND cm2.end_date IS NULL
  )
);
*/
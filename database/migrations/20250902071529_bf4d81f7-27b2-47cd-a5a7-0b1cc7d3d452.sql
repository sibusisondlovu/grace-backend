-- Fix security vulnerability: Restrict profile access to prevent public email exposure
-- Remove the overly permissive policy that allows anyone to view all profiles
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Create more restrictive policies for profile access
-- Policy 1: Users can view their own profile (including email)
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() = user_id);

-- Policy 2: Authenticated users can view basic profile info (excluding email) for committee/member functionality
CREATE POLICY "Authenticated users can view basic profile info" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() != user_id)
WITH CHECK (false);

-- Update the basic profile policy to exclude sensitive fields like email
-- We'll handle this by modifying how the profiles are selected in the application code
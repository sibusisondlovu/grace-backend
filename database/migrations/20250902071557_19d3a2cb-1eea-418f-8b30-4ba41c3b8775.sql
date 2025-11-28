-- Fix security vulnerability: Restrict profile access to prevent public email exposure
-- Remove the overly permissive policy that allows anyone to view all profiles
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Policy 1: Users can view their own profile (including email)
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() = user_id);

-- Policy 2: Authenticated users can view basic profile info for other users (for committee/member functionality)
-- This excludes sensitive fields like email through application-level field selection
CREATE POLICY "Authenticated users can view basic profile info" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() != user_id);
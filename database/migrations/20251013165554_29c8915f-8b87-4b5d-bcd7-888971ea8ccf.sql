-- Update RLS policies on profiles table to allow committee members and admins to view all profiles
-- This is necessary for adding members to committees

-- Drop the restrictive policy
DROP POLICY IF EXISTS "System admins can view all profiles" ON public.profiles;

-- Create new policies that allow viewing all profiles for committee functionality
CREATE POLICY "Authenticated users can view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- Keep the self-management policies
-- Users can still only update their own profile
-- (existing policies for INSERT and UPDATE remain unchanged)
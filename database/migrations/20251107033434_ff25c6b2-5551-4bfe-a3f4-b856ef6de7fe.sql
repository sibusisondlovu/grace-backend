-- Fix Storage Exposure: Make reports-library bucket private
-- This ensures reports are only accessible through proper RLS policies

-- Make the bucket private
UPDATE storage.buckets 
SET public = false 
WHERE id = 'reports-library';

-- Create RLS policies on storage.objects that mirror reports_library table permissions

-- Policy 1: Users can view authorized reports based on classification
CREATE POLICY "Users can view authorized reports"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'reports-library' AND
  EXISTS (
    SELECT 1 FROM reports_library r
    WHERE r.file_path = name AND (
      -- Public published reports are accessible to everyone
      (r.classification = 'public' AND r.publication_status = 'published') OR
      -- Committee-specific reports accessible to committee members
      (r.committee_id IS NOT NULL AND has_committee_access(auth.uid(), r.committee_id)) OR
      -- Admins can access all reports
      has_role(auth.uid(), 'admin'::app_role) OR
      -- Internal reports accessible to authenticated users
      (r.classification = 'internal' AND r.publication_status = 'published' AND auth.uid() IS NOT NULL)
    )
  )
);

-- Policy 2: Admins and authorized users can upload reports
CREATE POLICY "Authorized users can upload reports"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'reports-library' AND
  (
    has_role(auth.uid(), 'admin'::app_role) OR
    has_role(auth.uid(), 'coordinator'::app_role) OR
    has_role(auth.uid(), 'clerk'::app_role)
  )
);

-- Policy 3: Admins can update report files
CREATE POLICY "Admins can update reports"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'reports-library' AND
  has_role(auth.uid(), 'admin'::app_role)
);

-- Policy 4: Admins can delete report files
CREATE POLICY "Admins can delete reports"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'reports-library' AND
  has_role(auth.uid(), 'admin'::app_role)
);
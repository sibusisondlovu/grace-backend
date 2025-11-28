-- Update RLS policy to allow public access to published documents for public meetings
DROP POLICY IF EXISTS "Users can view published documents" ON public.meeting_documents;

CREATE POLICY "Public can view published documents for public meetings"
ON public.meeting_documents
FOR SELECT
USING (
  published = true AND
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_id AND m.public_meeting = true
  )
);

CREATE POLICY "Committee members can view all meeting documents"
ON public.meeting_documents
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_id 
    AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
  )
);

-- Update storage policy to allow public access to published meeting documents
DROP POLICY IF EXISTS "Users can view meeting document files" ON storage.objects;

CREATE POLICY "Public can view published meeting document files"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'meeting-documents' AND
  EXISTS (
    SELECT 1 FROM public.meeting_documents md
    JOIN public.meetings m ON m.id = md.meeting_id
    WHERE md.file_path = name 
    AND md.published = true 
    AND m.public_meeting = true
  )
);

CREATE POLICY "Committee members can view all meeting document files"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'meeting-documents' AND
  auth.role() = 'authenticated'
);
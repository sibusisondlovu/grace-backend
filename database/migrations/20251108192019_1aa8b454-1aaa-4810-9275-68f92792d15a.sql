-- Allow system-level document uploads (from Documents page)
-- These documents use a special UUID and don't require meeting association
CREATE POLICY "Allow system-level document uploads"
ON meeting_documents
FOR INSERT
WITH CHECK (
  meeting_id = '00000000-0000-0000-0000-000000000000'::uuid
  AND (
    has_role(auth.uid(), 'admin'::app_role) 
    OR has_role(auth.uid(), 'clerk'::app_role)
    OR has_role(auth.uid(), 'coordinator'::app_role)
  )
);
-- Create storage bucket for reports library PDFs
INSERT INTO storage.buckets (id, name, public)
VALUES ('reports-library', 'reports-library', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for reports-library bucket
CREATE POLICY "Public can view published reports"
ON storage.objects
FOR SELECT
USING (bucket_id = 'reports-library');

CREATE POLICY "Authenticated users can upload reports"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'reports-library' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Authenticated users can update their reports"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'reports-library' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete their reports"
ON storage.objects
FOR DELETE
USING (bucket_id = 'reports-library' AND auth.role() = 'authenticated');
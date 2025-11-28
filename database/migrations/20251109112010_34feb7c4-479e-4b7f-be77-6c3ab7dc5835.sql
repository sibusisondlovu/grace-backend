-- Create storage bucket for organization logos
INSERT INTO storage.buckets (id, name, public)
VALUES ('organization-logos', 'organization-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Add logo_url column to organizations table
ALTER TABLE public.organizations
ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Create RLS policies for organization logos bucket
CREATE POLICY "Anyone can view organization logos"
ON storage.objects FOR SELECT
USING (bucket_id = 'organization-logos');

CREATE POLICY "Admins can upload organization logos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'organization-logos' AND
  (
    public.has_role(auth.uid(), 'admin'::app_role) OR
    public.is_super_admin(auth.uid())
  )
);

CREATE POLICY "Admins can update organization logos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'organization-logos' AND
  (
    public.has_role(auth.uid(), 'admin'::app_role) OR
    public.is_super_admin(auth.uid())
  )
);

CREATE POLICY "Admins can delete organization logos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'organization-logos' AND
  (
    public.has_role(auth.uid(), 'admin'::app_role) OR
    public.is_super_admin(auth.uid())
  )
);
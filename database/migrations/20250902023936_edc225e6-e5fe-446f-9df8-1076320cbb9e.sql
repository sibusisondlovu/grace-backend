-- Create meeting_registrations table for public interest registration
CREATE TABLE public.meeting_registrations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL,
  user_id UUID NOT NULL,
  registration_type TEXT NOT NULL CHECK (registration_type IN ('observer', 'presenter', 'interested_party', 'media')),
  attendance_purpose TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(meeting_id, user_id)
);

-- Create meeting_documents table for agendas, minutes, and supporting documents
CREATE TABLE public.meeting_documents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id UUID NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('agenda', 'minutes', 'supporting')),
  title TEXT NOT NULL,
  file_path TEXT,
  content TEXT,
  published BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS for meeting_registrations
ALTER TABLE public.meeting_registrations ENABLE ROW LEVEL SECURITY;

-- Enable RLS for meeting_documents
ALTER TABLE public.meeting_documents ENABLE ROW LEVEL SECURITY;

-- RLS policies for meeting_registrations
CREATE POLICY "Users can view their own registrations"
ON public.meeting_registrations
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can register for public meetings"
ON public.meeting_registrations
FOR INSERT
WITH CHECK (
  auth.uid() = user_id AND
  EXISTS (
    SELECT 1 FROM public.meetings m 
    WHERE m.id = meeting_id AND m.public_meeting = true
  )
);

CREATE POLICY "Users can update their own registrations"
ON public.meeting_registrations
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own registrations"
ON public.meeting_registrations
FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Committee members can view meeting registrations"
ON public.meeting_registrations
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_id 
    AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
  )
);

-- RLS policies for meeting_documents
CREATE POLICY "Users can view published documents"
ON public.meeting_documents
FOR SELECT
USING (
  published = true OR
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_id 
    AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
  )
);

CREATE POLICY "Committee members can manage meeting documents"
ON public.meeting_documents
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.meetings m
    WHERE m.id = meeting_id 
    AND (has_committee_access(auth.uid(), m.committee_id) OR has_role(auth.uid(), 'admin'::app_role))
  )
);

-- Create storage bucket for meeting documents
INSERT INTO storage.buckets (id, name, public) VALUES ('meeting-documents', 'meeting-documents', false);

-- Storage policies for meeting documents
CREATE POLICY "Users can view meeting document files"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'meeting-documents' AND
  EXISTS (
    SELECT 1 FROM public.meeting_documents md
    WHERE md.file_path = name AND md.published = true
  )
);

CREATE POLICY "Committee members can upload meeting documents"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'meeting-documents' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Committee members can update meeting documents"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'meeting-documents' AND
  auth.role() = 'authenticated'
);

-- Add trigger for updating meeting_documents timestamps
CREATE TRIGGER update_meeting_documents_updated_at
BEFORE UPDATE ON public.meeting_documents
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
-- Create email notifications tracking table
CREATE TABLE IF NOT EXISTS public.email_notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  recipient_email TEXT NOT NULL,
  recipient_id UUID,
  subject TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'sent',
  sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.email_notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admins can view email notifications"
  ON public.email_notifications
  FOR SELECT
  USING (
    has_role(auth.uid(), 'admin'::app_role) 
    AND can_access_organization(auth.uid(), organization_id)
  );

CREATE POLICY "Super admins can view all email notifications"
  ON public.email_notifications
  FOR SELECT
  USING (is_super_admin(auth.uid()));

-- Create index for better performance
CREATE INDEX idx_email_notifications_org ON public.email_notifications(organization_id);
CREATE INDEX idx_email_notifications_recipient ON public.email_notifications(recipient_id);
CREATE INDEX idx_email_notifications_sent_at ON public.email_notifications(sent_at DESC);
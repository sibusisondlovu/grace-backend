-- Add Teams webhook configuration to organizations table
ALTER TABLE public.organizations 
ADD COLUMN IF NOT EXISTS teams_webhook_url TEXT;

-- Add comment
COMMENT ON COLUMN public.organizations.teams_webhook_url IS 'Microsoft Teams incoming webhook URL for notifications';

-- Create a table to track Teams notifications
CREATE TABLE IF NOT EXISTS public.teams_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  success BOOLEAN DEFAULT true,
  error_message TEXT,
  metadata JSONB
);

-- Enable RLS
ALTER TABLE public.teams_notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view notifications from their organization
CREATE POLICY "Users can view their organization's Teams notifications"
ON public.teams_notifications
FOR SELECT
USING (
  organization_id IN (
    SELECT organization_id FROM public.profiles WHERE user_id = auth.uid()
  )
);

-- Policy: Authenticated users can insert notifications
CREATE POLICY "Authenticated users can create Teams notifications"
ON public.teams_notifications
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_teams_notifications_org_id ON public.teams_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_teams_notifications_sent_at ON public.teams_notifications(sent_at DESC);
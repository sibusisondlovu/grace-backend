-- Fix function search path security warning
CREATE OR REPLACE FUNCTION public.log_committee_member_access()
RETURNS TRIGGER AS $$
BEGIN
  -- Log when sensitive political information is accessed
  IF TG_OP = 'SELECT' AND (NEW.party_affiliation IS NOT NULL OR NEW.ward_number IS NOT NULL) THEN
    PERFORM public.log_audit_event(
      'sensitive_data_access',
      'committee_members',
      NEW.id,
      NULL,
      jsonb_build_object(
        'accessed_user_id', NEW.user_id,
        'party_affiliation_accessed', (NEW.party_affiliation IS NOT NULL),
        'ward_number_accessed', (NEW.ward_number IS NOT NULL)
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
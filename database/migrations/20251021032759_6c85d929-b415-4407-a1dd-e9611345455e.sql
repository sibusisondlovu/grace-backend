-- Create document categories and classifications table
CREATE TABLE IF NOT EXISTS public.document_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  parent_category_id UUID REFERENCES public.document_categories(id),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create reports library table
CREATE TABLE IF NOT EXISTS public.reports_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  report_type TEXT NOT NULL, -- 'annual_report', 'oversight_report', 'citizens_report', 'budget', 'idp', 'by_law', 'policy', 'notice', 'other'
  financial_year TEXT, -- e.g., '2023/24'
  category_id UUID REFERENCES public.document_categories(id),
  classification TEXT NOT NULL DEFAULT 'public', -- 'public', 'internal', 'confidential'
  document_url TEXT,
  file_path TEXT,
  file_size BIGINT,
  description TEXT,
  published_date DATE,
  publication_status TEXT DEFAULT 'draft', -- 'draft', 'published', 'archived'
  committee_id UUID REFERENCES public.committees(id),
  linked_meeting_id UUID REFERENCES public.meetings(id),
  tags TEXT[],
  metadata JSONB,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_reports_library_report_type ON public.reports_library(report_type);
CREATE INDEX idx_reports_library_financial_year ON public.reports_library(financial_year);
CREATE INDEX idx_reports_library_category ON public.reports_library(category_id);
CREATE INDEX idx_reports_library_publication_status ON public.reports_library(publication_status);
CREATE INDEX idx_reports_library_tags ON public.reports_library USING GIN(tags);

-- Enable RLS
ALTER TABLE public.document_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports_library ENABLE ROW LEVEL SECURITY;

-- RLS Policies for document_categories
CREATE POLICY "Anyone can view document categories"
  ON public.document_categories FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage document categories"
  ON public.document_categories FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role));

-- RLS Policies for reports_library
CREATE POLICY "Anyone can view published public reports"
  ON public.reports_library FOR SELECT
  USING (publication_status = 'published' AND classification = 'public');

CREATE POLICY "Authenticated users can view internal reports"
  ON public.reports_library FOR SELECT
  USING (
    (publication_status = 'published' AND classification IN ('public', 'internal'))
    OR has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Admins can manage all reports"
  ON public.reports_library FOR ALL
  USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Committee members can view committee reports"
  ON public.reports_library FOR SELECT
  USING (
    (committee_id IS NOT NULL AND has_committee_access(auth.uid(), committee_id))
    OR has_role(auth.uid(), 'admin'::app_role)
  );

-- Trigger for updated_at
CREATE TRIGGER update_document_categories_updated_at
  BEFORE UPDATE ON public.document_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reports_library_updated_at
  BEFORE UPDATE ON public.reports_library
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default document categories based on COJ structure
INSERT INTO public.document_categories (name, description, display_order) VALUES
  ('Annual Reports', 'Integrated annual reports and related documents', 1),
  ('Oversight Reports', 'MPAC oversight reports on annual reports', 2),
  ('Budget Documents', 'Medium-term budgets, adjustment budgets, and SDBIP', 3),
  ('Integrated Development Plans', 'IDP documents and related planning', 4),
  ('By-Laws', 'Municipal by-laws and regulations', 5),
  ('Policies', 'Rates, tariffs, and other policy documents', 6),
  ('Performance Reports', 'Scorecards and performance agreements', 7),
  ('Strategic Documents', 'Joburg 2040 GDS and growth management strategies', 8),
  ('Statistical Reports', 'Statistical briefs and data reports', 9),
  ('Disciplinary Reports', 'Disciplinary board reports', 10),
  ('Public Notices', 'Official public notices and announcements', 11),
  ('Citizens Reports', 'Simplified annual reports for citizens', 12);

-- Insert sample historical reports from COJ website
INSERT INTO public.reports_library (title, report_type, financial_year, category_id, classification, document_url, published_date, publication_status, description) 
SELECT 
  'City of Johannesburg Integrated Annual Report 2023/24',
  'annual_report',
  '2023/24',
  (SELECT id FROM public.document_categories WHERE name = 'Annual Reports'),
  'public',
  'https://joburg.org.za/documents_/Pages/2023-24-Integrated-Annual-Report.aspx',
  '2024-11-01'::DATE,
  'published',
  'Comprehensive annual report covering financial and operational performance'
WHERE NOT EXISTS (
  SELECT 1 FROM public.reports_library WHERE title = 'City of Johannesburg Integrated Annual Report 2023/24'
);

INSERT INTO public.reports_library (title, report_type, financial_year, category_id, classification, document_url, published_date, publication_status, description)
SELECT
  'Oversight Report on the 2023/24 Annual Report by MPAC',
  'oversight_report',
  '2023/24',
  (SELECT id FROM public.document_categories WHERE name = 'Oversight Reports'),
  'public',
  'https://joburg.org.za/documents_/Documents/2023-24-Annual-Report/ITEM-02.pdf',
  '2025-03-24'::DATE,
  'published',
  'Municipal Public Accounts Committee oversight report on the 2023/24 annual report'
WHERE NOT EXISTS (
  SELECT 1 FROM public.reports_library WHERE title = 'Oversight Report on the 2023/24 Annual Report by MPAC'
);

INSERT INTO public.reports_library (title, report_type, financial_year, category_id, classification, document_url, published_date, publication_status, description)
SELECT
  'Integrated Annual Report 2022/23',
  'annual_report',
  '2022/23',
  (SELECT id FROM public.document_categories WHERE name = 'Annual Reports'),
  'public',
  'https://joburg.org.za/documents_/Pages/202223-Annual-Report.aspx',
  '2023-11-01'::DATE,
  'published',
  'Annual report for the 2022/23 financial year'
WHERE NOT EXISTS (
  SELECT 1 FROM public.reports_library WHERE title = 'Integrated Annual Report 2022/23'
);

INSERT INTO public.reports_library (title, report_type, financial_year, category_id, classification, document_url, published_date, publication_status, description)
SELECT
  'Oversight Report on the 2022/23 Annual Report by MPAC',
  'oversight_report',
  '2022/23',
  (SELECT id FROM public.document_categories WHERE name = 'Oversight Reports'),
  'public',
  'https://joburg.org.za/Documents/2024%20Notices/MPAC-OVERSIGHT-REPORT-ON-THE-2022-23-COJ-ANNUAL-ANNUAL-REPORT.pdf',
  '2024-03-01'::DATE,
  'published',
  'MPAC oversight report on the 2022/23 annual report'
WHERE NOT EXISTS (
  SELECT 1 FROM public.reports_library WHERE title = 'Oversight Report on the 2022/23 Annual Report by MPAC'
);

INSERT INTO public.reports_library (title, report_type, financial_year, category_id, classification, document_url, published_date, publication_status, description)
SELECT
  '2020/2021 Citizens Report',
  'citizens_report',
  '2020/21',
  (SELECT id FROM public.document_categories WHERE name = 'Citizens Reports'),
  'public',
  'https://joburg.org.za/documents_/Documents/2020-21%20Integrated%20Annual%20Report/CoJ%20IAR%202020_2021_CITIZENS%20REPORT_03%20March%202022.pdf',
  '2022-03-03'::DATE,
  'published',
  'Simplified annual report for citizens'
WHERE NOT EXISTS (
  SELECT 1 FROM public.reports_library WHERE title = '2020/2021 Citizens Report'
);
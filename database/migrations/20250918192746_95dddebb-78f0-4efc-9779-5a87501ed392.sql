-- Insert sample committees for mayoral, MPAC, and Section 79/80 oversight
INSERT INTO public.committees (name, type, description, terms_of_reference, quorum_percentage, notice_period_days, status, public_access_allowed, virtual_meetings_allowed) VALUES

-- Mayoral Committee
('Mayoral Committee', 'Executive', 'The Mayoral Committee serves as the executive authority of the municipality, responsible for policy implementation and strategic decision-making.', 'To exercise executive authority, implement council decisions, oversee municipal operations, and provide strategic leadership for service delivery including budget oversight, policy formulation, and strategic municipal management.', 60, 7, 'active', true, true),

-- MPAC Committee  
('Municipal Public Accounts Committee (MPAC)', 'Oversight', 'MPAC is responsible for overseeing the financial management and performance of the municipality, reviewing audit reports and ensuring accountability.', 'To review financial statements, audit reports, performance reports, and oversee municipal financial management and accountability. MPAC monitors compliance with legislation, reviews irregular expenditure, and ensures transparency in municipal financial operations.', 50, 5, 'active', true, false),

-- Section 79 Committee
('Section 79 Oversight Committee', 'Section 79', 'Established in terms of Section 79 of the Municipal Structures Act to oversee specific municipal functions and performance.', 'To monitor and review the performance of the municipality, oversee the implementation of the Integrated Development Plan (IDP), evaluate service delivery effectiveness, and ensure compliance with municipal mandates and legislative requirements.', 50, 5, 'active', false, true),

-- Section 80 Portfolio Committee - Infrastructure
('Section 80 Portfolio Committee - Infrastructure', 'Section 80', 'A portfolio committee focusing on infrastructure development, maintenance, and service delivery oversight.', 'To oversee infrastructure development, monitor service delivery in water, sanitation, electricity, roads, and housing. Review departmental performance, assess capital projects, and make recommendations to council on infrastructure priorities and maintenance programs.', 50, 5, 'active', true, true),

-- Additional Section 80 Portfolio Committee - Community Services
('Section 80 Portfolio Committee - Community Services', 'Section 80', 'Portfolio committee overseeing community development, social services, and public safety.', 'To oversee community development programs, social services delivery, public safety initiatives, parks and recreation, libraries, and community facilities. Monitor departmental performance and recommend policy improvements for enhanced community well-being.', 50, 5, 'active', true, true),

-- Additional Section 80 Portfolio Committee - Finance and Administration  
('Section 80 Portfolio Committee - Finance & Administration', 'Section 80', 'Portfolio committee responsible for financial oversight, human resources, and administrative functions.', 'To oversee municipal financial management, revenue collection, human resources, information technology, legal services, and administrative processes. Review budget implementation, assess financial controls, and ensure compliance with financial legislation.', 50, 5, 'active', true, true);

-- Insert sample meetings for these committees
DO $$
DECLARE
    mayoral_committee_id uuid;
    mpac_committee_id uuid;
    section79_committee_id uuid;
    section80_infra_id uuid;
    section80_community_id uuid;
    section80_finance_id uuid;
BEGIN
    -- Get committee IDs
    SELECT id INTO mayoral_committee_id FROM committees WHERE name = 'Mayoral Committee';
    SELECT id INTO mpac_committee_id FROM committees WHERE name = 'Municipal Public Accounts Committee (MPAC)';
    SELECT id INTO section79_committee_id FROM committees WHERE name = 'Section 79 Oversight Committee';
    SELECT id INTO section80_infra_id FROM committees WHERE name = 'Section 80 Portfolio Committee - Infrastructure';
    SELECT id INTO section80_community_id FROM committees WHERE name = 'Section 80 Portfolio Committee - Community Services';
    SELECT id INTO section80_finance_id FROM committees WHERE name = 'Section 80 Portfolio Committee - Finance & Administration';

    -- Insert upcoming meetings
    INSERT INTO public.meetings (committee_id, title, meeting_date, venue, meeting_type, status, public_meeting, agenda_published, minutes_published) VALUES
    (mayoral_committee_id, 'Monthly Mayoral Committee Meeting', NOW() + interval '7 days', 'Council Chambers', 'physical', 'scheduled', true, true, false),
    (mayoral_committee_id, 'Special Mayoral Committee - Budget Review', NOW() + interval '21 days', 'Council Chambers', 'physical', 'scheduled', true, false, false),
    
    (mpac_committee_id, 'MPAC Quarterly Review Meeting', NOW() + interval '14 days', 'Committee Room A', 'hybrid', 'scheduled', true, false, false),
    (mpac_committee_id, 'MPAC Annual Report Review', NOW() + interval '35 days', 'Committee Room A', 'physical', 'scheduled', true, false, false),
    
    (section79_committee_id, 'Section 79 Oversight Review - Q2', NOW() + interval '21 days', 'Virtual Meeting Platform', 'virtual', 'scheduled', false, false, false),
    (section79_committee_id, 'IDP Mid-Year Assessment', NOW() + interval '42 days', 'Committee Room B', 'hybrid', 'scheduled', false, false, false),
    
    (section80_infra_id, 'Infrastructure Portfolio Review', NOW() + interval '10 days', 'Committee Room B', 'physical', 'scheduled', true, true, false),
    (section80_infra_id, 'Water & Sanitation Service Review', NOW() + interval '28 days', 'Committee Room B', 'physical', 'scheduled', true, false, false),
    
    (section80_community_id, 'Community Services Portfolio Meeting', NOW() + interval '12 days', 'Community Hall', 'physical', 'scheduled', true, true, false),
    (section80_community_id, 'Public Safety & Emergency Services Review', NOW() + interval '30 days', 'Committee Room C', 'hybrid', 'scheduled', true, false, false),
    
    (section80_finance_id, 'Finance & Administration Portfolio Meeting', NOW() + interval '15 days', 'Committee Room A', 'physical', 'scheduled', true, false, false),
    (section80_finance_id, 'Revenue Collection & Financial Controls Review', NOW() + interval '45 days', 'Committee Room A', 'physical', 'scheduled', true, false, false);

    -- Insert sample action items
    INSERT INTO public.action_items (committee_id, title, description, assigned_to_department, priority, status, due_date) VALUES
    -- Mayoral Committee actions
    (mayoral_committee_id, 'Review Annual Budget Adjustments', 'Review and approve mid-year budget adjustments for the 2024/25 financial year, focusing on capital expenditure reallocations and operational budget optimization.', 'Finance Department', 'high', 'pending', CURRENT_DATE + interval '30 days'),
    (mayoral_committee_id, 'Strategic Plan Implementation Review', 'Conduct comprehensive review of 5-year strategic plan implementation and identify areas requiring intervention or resource reallocation.', 'Office of the City Manager', 'high', 'in_progress', CURRENT_DATE + interval '45 days'),
    (mayoral_committee_id, 'Public Participation Framework Update', 'Update the public participation framework to enhance community engagement in municipal decision-making processes.', 'Communications Department', 'medium', 'pending', CURRENT_DATE + interval '60 days'),
    
    -- MPAC actions
    (mpac_committee_id, 'Audit Report Analysis - AG Findings', 'Analyze findings from the latest Auditor-General report and prepare comprehensive management response with corrective action plans.', 'Internal Audit', 'high', 'pending', CURRENT_DATE + interval '21 days'),
    (mpac_committee_id, 'Financial Performance Review Q2', 'Review Q2 financial performance against budget targets and identify corrective measures for revenue enhancement and expenditure control.', 'Finance Department', 'high', 'in_progress', CURRENT_DATE + interval '14 days'),
    (mpac_committee_id, 'Supply Chain Management Compliance Review', 'Conduct comprehensive review of supply chain management processes and compliance with Municipal Finance Management Act requirements.', 'Supply Chain Management', 'high', 'assigned', CURRENT_DATE + interval '35 days'),
    (mpac_committee_id, 'Irregular Expenditure Investigation', 'Investigate and report on irregular expenditure incidents, including recovery plans and disciplinary actions where applicable.', 'Legal Services', 'high', 'pending', CURRENT_DATE + interval '28 days'),
    
    -- Section 79 actions
    (section79_committee_id, 'Service Delivery Monitoring Report', 'Prepare comprehensive service delivery monitoring report covering all municipal services with performance indicators and improvement recommendations.', 'Community Services', 'medium', 'pending', CURRENT_DATE + interval '28 days'),
    (section79_committee_id, 'IDP Implementation Review', 'Review progress on Integrated Development Plan implementation with focus on priority projects and budget allocation effectiveness.', 'IDP Coordinating Unit', 'high', 'in_progress', CURRENT_DATE + interval '21 days'),
    (section79_committee_id, 'Municipal Transformation Assessment', 'Assess municipal transformation initiatives and employment equity compliance across all departments.', 'Human Resources', 'medium', 'pending', CURRENT_DATE + interval '42 days'),
    
    -- Section 80 Infrastructure actions
    (section80_infra_id, 'Water Infrastructure Assessment', 'Conduct comprehensive assessment of water infrastructure maintenance needs and develop 3-year maintenance plan with budget implications.', 'Water & Sanitation', 'high', 'assigned', CURRENT_DATE + interval '42 days'),
    (section80_infra_id, 'Road Maintenance Program Review', 'Review and update the annual road maintenance program with priority ranking and resource allocation recommendations.', 'Roads & Transport', 'medium', 'pending', CURRENT_DATE + interval '60 days'),
    (section80_infra_id, 'Electricity Infrastructure Audit', 'Conduct audit of electricity infrastructure including distribution networks, substations, and maintenance backlogs.', 'Electricity Department', 'high', 'pending', CURRENT_DATE + interval '50 days'),
    
    -- Section 80 Community Services actions
    (section80_community_id, 'Community Infrastructure Needs Survey', 'Conduct comprehensive survey to identify priority infrastructure needs in underserved communities with cost estimates.', 'Community Development', 'medium', 'pending', CURRENT_DATE + interval '90 days'),
    (section80_community_id, 'Public Safety Strategy Review', 'Review public safety strategy including crime prevention, disaster management, and emergency response capabilities.', 'Public Safety', 'high', 'assigned', CURRENT_DATE + interval '35 days'),
    (section80_community_id, 'Recreation Facilities Assessment', 'Assess condition and utilization of recreation facilities including parks, sports grounds, and community centers.', 'Parks & Recreation', 'medium', 'pending', CURRENT_DATE + interval '75 days'),
    
    -- Section 80 Finance actions
    (section80_finance_id, 'Revenue Enhancement Strategy', 'Develop comprehensive revenue enhancement strategy including property rates optimization and debt collection improvement.', 'Revenue Management', 'high', 'in_progress', CURRENT_DATE + interval '40 days'),
    (section80_finance_id, 'Financial System Upgrade Assessment', 'Assess current financial management systems and recommend upgrades for improved efficiency and compliance.', 'Information Technology', 'medium', 'pending', CURRENT_DATE + interval '60 days'),
    (section80_finance_id, 'Human Resources Policy Review', 'Review and update human resources policies to ensure compliance with labor legislation and municipal requirements.', 'Human Resources', 'medium', 'assigned', CURRENT_DATE + interval '55 days');

END $$;
-- Insert sample profiles for committee members
INSERT INTO public.profiles (user_id, first_name, last_name, email, phone, job_title, department) VALUES
-- Generate UUIDs for sample users
(gen_random_uuid(), 'Sarah', 'Johnson', 'sarah.johnson@municipality.gov.za', '+27-11-555-0101', 'Mayor', 'Office of the Mayor'),
(gen_random_uuid(), 'Michael', 'Ndaba', 'michael.ndaba@municipality.gov.za', '+27-11-555-0102', 'Chief Financial Officer', 'Finance Department'),
(gen_random_uuid(), 'Priya', 'Patel', 'priya.patel@municipality.gov.za', '+27-11-555-0103', 'City Manager', 'Administration'),
(gen_random_uuid(), 'James', 'Mthembu', 'james.mthembu@municipality.gov.za', '+27-11-555-0104', 'Councillor', 'Ward 15'),
(gen_random_uuid(), 'Linda', 'van der Merwe', 'linda.vandermerwe@municipality.gov.za', '+27-11-555-0105', 'Councillor', 'Ward 8'),
(gen_random_uuid(), 'Thabo', 'Mokoena', 'thabo.mokoena@municipality.gov.za', '+27-11-555-0106', 'Internal Auditor', 'Internal Audit'),
(gen_random_uuid(), 'Jennifer', 'Smith', 'jennifer.smith@municipality.gov.za', '+27-11-555-0107', 'Legal Advisor', 'Legal Services'),
(gen_random_uuid(), 'Ahmed', 'Hassan', 'ahmed.hassan@municipality.gov.za', '+27-11-555-0108', 'Head of Infrastructure', 'Infrastructure Development'),
(gen_random_uuid(), 'Mary', 'Khumalo', 'mary.khumalo@municipality.gov.za', '+27-11-555-0109', 'Councillor', 'Ward 22'),
(gen_random_uuid(), 'David', 'Robertson', 'david.robertson@municipality.gov.za', '+27-11-555-0110', 'Community Development Manager', 'Community Services');

-- Create variables to store user IDs for reference
DO $$
DECLARE
    mayor_id uuid;
    cfo_id uuid;
    city_manager_id uuid;
    councillor1_id uuid;
    councillor2_id uuid;
    auditor_id uuid;
    legal_id uuid;
    infrastructure_id uuid;
    councillor3_id uuid;
    community_id uuid;
    
    mayoral_committee_id uuid;
    mpac_committee_id uuid;
    section79_committee_id uuid;
    section80_committee_id uuid;
    
    meeting1_id uuid;
    meeting2_id uuid;
    meeting3_id uuid;
    meeting4_id uuid;
BEGIN
    -- Get the user IDs we just created
    SELECT user_id INTO mayor_id FROM profiles WHERE email = 'sarah.johnson@municipality.gov.za';
    SELECT user_id INTO cfo_id FROM profiles WHERE email = 'michael.ndaba@municipality.gov.za';
    SELECT user_id INTO city_manager_id FROM profiles WHERE email = 'priya.patel@municipality.gov.za';
    SELECT user_id INTO councillor1_id FROM profiles WHERE email = 'james.mthembu@municipality.gov.za';
    SELECT user_id INTO councillor2_id FROM profiles WHERE email = 'linda.vandermerwe@municipality.gov.za';
    SELECT user_id INTO auditor_id FROM profiles WHERE email = 'thabo.mokoena@municipality.gov.za';
    SELECT user_id INTO legal_id FROM profiles WHERE email = 'jennifer.smith@municipality.gov.za';
    SELECT user_id INTO infrastructure_id FROM profiles WHERE email = 'ahmed.hassan@municipality.gov.za';
    SELECT user_id INTO councillor3_id FROM profiles WHERE email = 'mary.khumalo@municipality.gov.za';
    SELECT user_id INTO community_id FROM profiles WHERE email = 'david.robertson@municipality.gov.za';

    -- Insert committees
    INSERT INTO public.committees (id, name, type, description, terms_of_reference, chair_id, deputy_chair_id, quorum_percentage, notice_period_days, status, public_access_allowed, virtual_meetings_allowed) VALUES
    (gen_random_uuid(), 'Mayoral Committee', 'Executive', 'The Mayoral Committee serves as the executive authority of the municipality, responsible for policy implementation and strategic decision-making.', 'To exercise executive authority, implement council decisions, oversee municipal operations, and provide strategic leadership for service delivery.', mayor_id, city_manager_id, 60, 7, 'active', true, true),
    (gen_random_uuid(), 'Municipal Public Accounts Committee (MPAC)', 'Oversight', 'MPAC is responsible for overseeing the financial management and performance of the municipality, reviewing audit reports and ensuring accountability.', 'To review financial statements, audit reports, performance reports, and oversee municipal financial management and accountability.', councillor1_id, councillor2_id, 50, 5, 'active', true, false),
    (gen_random_uuid(), 'Section 79 Oversight Committee', 'Section 79', 'Established in terms of Section 79 of the Municipal Structures Act to oversee specific municipal functions and performance.', 'To monitor and review the performance of the municipality, oversee the implementation of the IDP, and ensure effective service delivery.', councillor2_id, councillor3_id, 50, 5, 'active', false, true),
    (gen_random_uuid(), 'Section 80 Portfolio Committee - Infrastructure', 'Section 80', 'A portfolio committee focusing on infrastructure development, maintenance, and service delivery oversight.', 'To oversee infrastructure development, monitor service delivery, review departmental performance, and make recommendations to council.', councillor3_id, infrastructure_id, 50, 5, 'active', true, true);

    -- Get committee IDs
    SELECT id INTO mayoral_committee_id FROM committees WHERE name = 'Mayoral Committee';
    SELECT id INTO mpac_committee_id FROM committees WHERE name = 'Municipal Public Accounts Committee (MPAC)';
    SELECT id INTO section79_committee_id FROM committees WHERE name = 'Section 79 Oversight Committee';
    SELECT id INTO section80_committee_id FROM committees WHERE name = 'Section 80 Portfolio Committee - Infrastructure';

    -- Insert committee members
    INSERT INTO public.committee_members (committee_id, user_id, role, party_affiliation, ward_number, voting_rights, start_date) VALUES
    -- Mayoral Committee
    (mayoral_committee_id, mayor_id, 'chairperson', 'ANC', NULL, true, CURRENT_DATE - interval '1 year'),
    (mayoral_committee_id, city_manager_id, 'deputy_chair', NULL, NULL, false, CURRENT_DATE - interval '1 year'),
    (mayoral_committee_id, cfo_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '10 months'),
    (mayoral_committee_id, legal_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '8 months'),
    (mayoral_committee_id, infrastructure_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '6 months'),
    
    -- MPAC
    (mpac_committee_id, councillor1_id, 'chairperson', 'DA', 'Ward 15', true, CURRENT_DATE - interval '1 year'),
    (mpac_committee_id, councillor2_id, 'deputy_chair', 'EFF', 'Ward 8', true, CURRENT_DATE - interval '1 year'),
    (mpac_committee_id, auditor_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '11 months'),
    (mpac_committee_id, cfo_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '9 months'),
    (mpac_committee_id, councillor3_id, 'member', 'ANC', 'Ward 22', true, CURRENT_DATE - interval '7 months'),
    
    -- Section 79 Committee
    (section79_committee_id, councillor2_id, 'chairperson', 'EFF', 'Ward 8', true, CURRENT_DATE - interval '1 year'),
    (section79_committee_id, councillor3_id, 'deputy_chair', 'ANC', 'Ward 22', true, CURRENT_DATE - interval '1 year'),
    (section79_committee_id, community_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '8 months'),
    (section79_committee_id, city_manager_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '6 months'),
    
    -- Section 80 Committee
    (section80_committee_id, councillor3_id, 'chairperson', 'ANC', 'Ward 22', true, CURRENT_DATE - interval '1 year'),
    (section80_committee_id, infrastructure_id, 'deputy_chair', NULL, NULL, false, CURRENT_DATE - interval '1 year'),
    (section80_committee_id, councillor1_id, 'member', 'DA', 'Ward 15', true, CURRENT_DATE - interval '10 months'),
    (section80_committee_id, community_id, 'member', NULL, NULL, false, CURRENT_DATE - interval '5 months');

    -- Insert meetings
    INSERT INTO public.meetings (id, committee_id, title, meeting_date, venue, meeting_type, status, public_meeting, agenda_published, minutes_published) VALUES
    (gen_random_uuid(), mayoral_committee_id, 'Monthly Mayoral Committee Meeting', NOW() + interval '7 days', 'Council Chambers', 'physical', 'scheduled', true, true, false),
    (gen_random_uuid(), mpac_committee_id, 'MPAC Quarterly Review Meeting', NOW() + interval '14 days', 'Committee Room A', 'hybrid', 'scheduled', true, false, false),
    (gen_random_uuid(), section79_committee_id, 'Section 79 Oversight Review', NOW() + interval '21 days', 'Virtual Meeting Platform', 'virtual', 'scheduled', false, false, false),
    (gen_random_uuid(), section80_committee_id, 'Infrastructure Portfolio Review', NOW() + interval '10 days', 'Committee Room B', 'physical', 'scheduled', true, true, false);

    -- Get meeting IDs
    SELECT id INTO meeting1_id FROM meetings WHERE title = 'Monthly Mayoral Committee Meeting';
    SELECT id INTO meeting2_id FROM meetings WHERE title = 'MPAC Quarterly Review Meeting';
    SELECT id INTO meeting3_id FROM meetings WHERE title = 'Section 79 Oversight Review';
    SELECT id INTO meeting4_id FROM meetings WHERE title = 'Infrastructure Portfolio Review';

    -- Insert action items
    INSERT INTO public.action_items (committee_id, meeting_id, title, description, assigned_to_id, assigned_to_department, priority, status, due_date) VALUES
    -- Mayoral Committee actions
    (mayoral_committee_id, meeting1_id, 'Review Annual Budget Adjustments', 'Review and approve mid-year budget adjustments for the 2024/25 financial year', cfo_id, 'Finance Department', 'high', 'pending', CURRENT_DATE + interval '30 days'),
    (mayoral_committee_id, meeting1_id, 'Infrastructure Development Plan Update', 'Update the 5-year infrastructure development plan based on community needs assessment', infrastructure_id, 'Infrastructure Development', 'medium', 'in_progress', CURRENT_DATE + interval '45 days'),
    
    -- MPAC actions
    (mpac_committee_id, meeting2_id, 'Audit Report Analysis', 'Analyze findings from the latest internal audit report and prepare response plan', auditor_id, 'Internal Audit', 'high', 'pending', CURRENT_DATE + interval '21 days'),
    (mpac_committee_id, meeting2_id, 'Financial Performance Review', 'Review Q2 financial performance against budget and identify corrective measures', cfo_id, 'Finance Department', 'high', 'pending', CURRENT_DATE + interval '14 days'),
    (mpac_committee_id, meeting2_id, 'Supply Chain Management Review', 'Review supply chain management processes and compliance with regulations', legal_id, 'Legal Services', 'medium', 'assigned', CURRENT_DATE + interval '35 days'),
    
    -- Section 79 actions
    (section79_committee_id, meeting3_id, 'Service Delivery Monitoring Report', 'Prepare comprehensive service delivery monitoring report for council', community_id, 'Community Services', 'medium', 'pending', CURRENT_DATE + interval '28 days'),
    (section79_committee_id, meeting3_id, 'IDP Implementation Review', 'Review progress on Integrated Development Plan implementation', city_manager_id, 'Administration', 'high', 'in_progress', CURRENT_DATE + interval '21 days'),
    
    -- Section 80 actions
    (section80_committee_id, meeting4_id, 'Water Infrastructure Assessment', 'Conduct comprehensive assessment of water infrastructure maintenance needs', infrastructure_id, 'Infrastructure Development', 'high', 'assigned', CURRENT_DATE + interval '42 days'),
    (section80_committee_id, meeting4_id, 'Road Maintenance Program Review', 'Review and update the annual road maintenance program', infrastructure_id, 'Infrastructure Development', 'medium', 'pending', CURRENT_DATE + interval '60 days'),
    (section80_committee_id, meeting4_id, 'Community Infrastructure Needs Survey', 'Conduct survey to identify priority infrastructure needs in underserved communities', community_id, 'Community Services', 'medium', 'pending', CURRENT_DATE + interval '90 days');

END $$;
-- Insert sample profiles
INSERT INTO public.profiles (user_id, first_name, last_name, email, phone, job_title, department) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Sarah', 'Johnson', 'sarah.johnson@joburg.org.za', '+27 11 407 7911', 'City Manager', 'Executive'),
  ('22222222-2222-2222-2222-222222222222', 'Michael', 'Ndaba', 'michael.ndaba@joburg.org.za', '+27 11 407 7912', 'MMC for Finance', 'Finance'),
  ('33333333-3333-3333-3333-333333333333', 'Priya', 'Patel', 'priya.patel@joburg.org.za', '+27 11 407 7913', 'Director of Planning', 'Development Planning'),
  ('44444444-4444-4444-4444-444444444444', 'John', 'van der Merwe', 'john.vandermerwe@joburg.org.za', '+27 11 407 7914', 'Ward Councillor', 'Ward 23'),
  ('55555555-5555-5555-5555-555555555555', 'Nomsa', 'Mthembu', 'nomsa.mthembu@joburg.org.za', '+27 11 407 7915', 'Chief Financial Officer', 'Finance'),
  ('66666666-6666-6666-6666-666666666666', 'David', 'Smith', 'david.smith@joburg.org.za', '+27 11 407 7916', 'Infrastructure Manager', 'Infrastructure'),
  ('77777777-7777-7777-7777-777777777777', 'Thandiwe', 'Mogale', 'thandiwe.mogale@joburg.org.za', '+27 11 407 7917', 'Environmental Officer', 'Environment'),
  ('88888888-8888-8888-8888-888888888888', 'Robert', 'Williams', 'robert.williams@joburg.org.za', '+27 11 407 7918', 'Legal Advisor', 'Legal Services');

-- Insert sample committees
INSERT INTO public.committees (id, name, type, description, terms_of_reference, chair_id, deputy_chair_id, status, quorum_percentage, notice_period_days) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Finance Committee', 'Standing', 'Oversees municipal finances, budgets, and fiscal policy decisions', 'To review and approve annual budgets, monitor financial performance, and ensure fiscal responsibility', '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'active', 60, 7),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Development Planning Committee', 'Standing', 'Reviews development applications and urban planning matters', 'To evaluate development proposals, ensure compliance with zoning regulations, and guide urban growth', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', 'active', 50, 5),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Infrastructure & Services Committee', 'Standing', 'Manages city infrastructure projects and service delivery', 'To oversee infrastructure development, maintenance, and service delivery optimization', '66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'active', 55, 7),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Environmental Management Committee', 'Standing', 'Addresses environmental concerns and sustainability initiatives', 'To develop environmental policies, monitor compliance, and promote sustainable practices', '77777777-7777-7777-7777-777777777777', '33333333-3333-3333-3333-333333333333', 'active', 50, 5),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Municipal Public Accounts Committee', 'Oversight', 'Reviews municipal expenditure and ensures accountability', 'To examine financial statements, audit reports, and ensure transparent use of public funds', '88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', 'active', 60, 10);

-- Insert committee members
INSERT INTO public.committee_members (committee_id, user_id, role, voting_rights, party_affiliation, ward_number) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'chairperson', true, 'ANC', null),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', 'deputy_chairperson', true, 'ANC', null),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'member', true, 'ANC', null),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444', 'member', true, 'DA', '23'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 'chairperson', true, 'DA', null),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 'deputy_chairperson', true, 'DA', '23'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-7777-7777-7777-777777777777', 'member', true, 'ANC', null),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '66666666-6666-6666-6666-666666666666', 'member', true, 'EFF', null),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '66666666-6666-6666-6666-666666666666', 'chairperson', true, 'ANC', null),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'deputy_chairperson', true, 'ANC', null),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'member', true, 'ANC', null),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '88888888-8888-8888-8888-888888888888', 'member', false, null, null),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '77777777-7777-7777-7777-777777777777', 'chairperson', true, 'ANC', null),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333', 'deputy_chairperson', true, 'DA', null),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '88888888-8888-8888-8888-888888888888', 'chairperson', true, 'DA', null),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '22222222-2222-2222-2222-222222222222', 'deputy_chairperson', true, 'ANC', null);

-- Insert sample meetings
INSERT INTO public.meetings (id, committee_id, title, meeting_date, venue, meeting_type, status, public_meeting, agenda_published) VALUES
  ('f1111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Monthly Budget Review', '2024-01-15 14:00:00+02', 'Council Chambers', 'physical', 'completed', true, true),
  ('f2222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Sandton Development Applications', '2024-01-18 10:00:00+02', 'Planning Hall B', 'physical', 'completed', true, true),
  ('f3333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Road Maintenance Program Review', '2024-01-22 09:00:00+02', 'Infrastructure Center', 'hybrid', 'completed', true, true),
  ('f4444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Annual Budget Planning Session', '2024-02-05 13:30:00+02', 'Council Chambers', 'physical', 'scheduled', true, false),
  ('f5555555-5555-5555-5555-555555555555', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Climate Change Adaptation Strategy', '2024-02-08 11:00:00+02', 'Virtual Meeting', 'virtual', 'scheduled', true, true),
  ('f6666666-6666-6666-6666-666666666666', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Soweto Housing Development Review', '2024-02-12 14:00:00+02', 'Soweto Civic Center', 'physical', 'scheduled', true, false);

-- Insert sample agenda items
INSERT INTO public.agenda_items (id, meeting_id, item_number, title, description, item_type, order_index, requires_vote, estimated_duration) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '1.1', 'Opening and Welcome', 'Chairperson opens meeting and welcomes attendees', 'procedural', 1, false, 5),
  ('a2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', '2.1', 'Q2 Financial Performance Report', 'Review of second quarter financial results and variance analysis', 'report', 2, false, 45),
  ('a3333333-3333-3333-3333-333333333333', 'f1111111-1111-1111-1111-111111111111', '3.1', 'Budget Adjustment Proposals', 'Proposed mid-year budget adjustments for infrastructure projects', 'motion', 3, true, 60),
  ('a4444444-4444-4444-4444-444444444444', 'f2222222-2222-2222-2222-222222222222', '1.1', 'Sandton Mixed-Use Development Application', 'Review of proposed 40-story mixed-use development in Sandton CBD', 'application', 1, true, 90),
  ('a5555555-5555-5555-5555-555555555555', 'f2222222-2222-2222-2222-222222222222', '2.1', 'Zoning Amendment - Rosebank', 'Request to rezone commercial property for residential development', 'application', 2, true, 45);

-- Insert sample action items
INSERT INTO public.action_items (id, title, description, status, priority, due_date, committee_id, meeting_id, agenda_item_id, assigned_to_id, assigned_to_department) VALUES
  ('ac111111-1111-1111-1111-111111111111', 'Prepare Infrastructure Budget Allocation Report', 'Compile detailed report on proposed infrastructure budget allocations for next fiscal year', 'in_progress', 'high', '2024-02-01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'f1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555555', 'Finance'),
  ('ac222222-2222-2222-2222-222222222222', 'Conduct Traffic Impact Assessment', 'Complete traffic impact study for Sandton mixed-use development', 'pending', 'high', '2024-01-30', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'f2222222-2222-2222-2222-222222222222', 'a4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'Development Planning'),
  ('ac333333-3333-3333-3333-333333333333', 'Schedule Road Maintenance Inspections', 'Organize monthly road condition inspections for priority routes', 'completed', 'medium', '2024-01-25', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'f3333333-3333-3333-3333-333333333333', null, '66666666-6666-6666-6666-666666666666', 'Infrastructure'),
  ('ac444444-4444-4444-4444-444444444444', 'Update Environmental Compliance Guidelines', 'Revise guidelines to reflect new national environmental regulations', 'in_progress', 'medium', '2024-02-15', 'dddddddd-dddd-dddd-dddd-dddddddddddd', null, null, '77777777-7777-7777-7777-777777777777', 'Environment'),
  ('ac555555-5555-5555-5555-555555555555', 'Review Public Participation Process', 'Evaluate current public participation procedures for development applications', 'pending', 'low', '2024-02-20', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', null, null, '33333333-3333-3333-3333-333333333333', 'Development Planning');

-- Insert meeting attendance records
INSERT INTO public.meeting_attendance (meeting_id, user_id, attendance_status, arrival_time, departure_time) VALUES
  ('f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'present', '2024-01-15 13:55:00+02', '2024-01-15 16:30:00+02'),
  ('f1111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'present', '2024-01-15 14:00:00+02', '2024-01-15 16:30:00+02'),
  ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'present', '2024-01-15 14:05:00+02', '2024-01-15 16:30:00+02'),
  ('f1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'apologies', null, null),
  ('f2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'present', '2024-01-18 09:55:00+02', '2024-01-18 12:45:00+02'),
  ('f2222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'present', '2024-01-18 10:00:00+02', '2024-01-18 12:45:00+02'),
  ('f2222222-2222-2222-2222-222222222222', '77777777-7777-7777-7777-777777777777', 'present', '2024-01-18 10:10:00+02', '2024-01-18 12:45:00+02'),
  ('f3333333-3333-3333-3333-333333333333', '66666666-6666-6666-6666-666666666666', 'present', '2024-01-22 08:55:00+02', '2024-01-22 11:30:00+02'),
  ('f3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'present', '2024-01-22 09:00:00+02', '2024-01-22 11:30:00+02');

-- Insert user roles
INSERT INTO public.user_roles (user_id, role, committee_id) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin', null),
  ('22222222-2222-2222-2222-222222222222', 'committee_member', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('33333333-3333-3333-3333-333333333333', 'committee_member', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  ('66666666-6666-6666-6666-666666666666', 'committee_member', 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  ('77777777-7777-7777-7777-777777777777', 'committee_member', 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  ('88888888-8888-8888-8888-888888888888', 'committee_member', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');
-- Insert sample committees (without user references initially)
INSERT INTO public.committees (id, name, type, description, terms_of_reference, status, quorum_percentage, notice_period_days) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Finance Committee', 'Standing', 'Oversees municipal finances, budgets, and fiscal policy decisions', 'To review and approve annual budgets, monitor financial performance, and ensure fiscal responsibility', 'active', 60, 7),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Development Planning Committee', 'Standing', 'Reviews development applications and urban planning matters', 'To evaluate development proposals, ensure compliance with zoning regulations, and guide urban growth', 'active', 50, 5),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Infrastructure & Services Committee', 'Standing', 'Manages city infrastructure projects and service delivery', 'To oversee infrastructure development, maintenance, and service delivery optimization', 'active', 55, 7),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Environmental Management Committee', 'Standing', 'Addresses environmental concerns and sustainability initiatives', 'To develop environmental policies, monitor compliance, and promote sustainable practices', 'active', 50, 5),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Municipal Public Accounts Committee', 'Oversight', 'Reviews municipal expenditure and ensures accountability', 'To examine financial statements, audit reports, and ensure transparent use of public funds', 'active', 60, 10);

-- Insert sample meetings
INSERT INTO public.meetings (id, committee_id, title, meeting_date, venue, meeting_type, status, public_meeting, agenda_published) VALUES
  ('f1111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Monthly Budget Review', '2024-03-15 14:00:00+02', 'Council Chambers', 'physical', 'completed', true, true),
  ('f2222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Sandton Development Applications', '2024-03-18 10:00:00+02', 'Planning Hall B', 'physical', 'completed', true, true),
  ('f3333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Road Maintenance Program Review', '2024-03-22 09:00:00+02', 'Infrastructure Center', 'hybrid', 'completed', true, true),
  ('f4444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Annual Budget Planning Session', '2024-04-05 13:30:00+02', 'Council Chambers', 'physical', 'scheduled', true, false),
  ('f5555555-5555-5555-5555-555555555555', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Climate Change Adaptation Strategy', '2024-04-08 11:00:00+02', 'Virtual Meeting', 'virtual', 'scheduled', true, true),
  ('f6666666-6666-6666-6666-666666666666', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Soweto Housing Development Review', '2024-04-12 14:00:00+02', 'Soweto Civic Center', 'physical', 'scheduled', true, false);

-- Insert sample agenda items
INSERT INTO public.agenda_items (id, meeting_id, item_number, title, description, item_type, order_index, requires_vote, estimated_duration) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '1.1', 'Opening and Welcome', 'Chairperson opens meeting and welcomes attendees', 'procedural', 1, false, 5),
  ('a2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', '2.1', 'Q2 Financial Performance Report', 'Review of second quarter financial results and variance analysis', 'report', 2, false, 45),
  ('a3333333-3333-3333-3333-333333333333', 'f1111111-1111-1111-1111-111111111111', '3.1', 'Budget Adjustment Proposals', 'Proposed mid-year budget adjustments for infrastructure projects', 'motion', 3, true, 60),
  ('a4444444-4444-4444-4444-444444444444', 'f2222222-2222-2222-2222-222222222222', '1.1', 'Sandton Mixed-Use Development Application', 'Review of proposed 40-story mixed-use development in Sandton CBD', 'application', 1, true, 90),
  ('a5555555-5555-5555-5555-555555555555', 'f2222222-2222-2222-2222-222222222222', '2.1', 'Zoning Amendment - Rosebank', 'Request to rezone commercial property for residential development', 'application', 2, true, 45);

-- Insert sample action items (without assigned_to_id initially)
INSERT INTO public.action_items (id, title, description, status, priority, due_date, committee_id, meeting_id, agenda_item_id, assigned_to_department) VALUES
  ('ac111111-1111-1111-1111-111111111111', 'Prepare Infrastructure Budget Allocation Report', 'Compile detailed report on proposed infrastructure budget allocations for next fiscal year', 'in_progress', 'high', '2024-04-01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'f1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'Finance'),
  ('ac222222-2222-2222-2222-222222222222', 'Conduct Traffic Impact Assessment', 'Complete traffic impact study for Sandton mixed-use development', 'pending', 'high', '2024-04-30', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'f2222222-2222-2222-2222-222222222222', 'a4444444-4444-4444-4444-444444444444', 'Development Planning'),
  ('ac333333-3333-3333-3333-333333333333', 'Schedule Road Maintenance Inspections', 'Organize monthly road condition inspections for priority routes', 'completed', 'medium', '2024-03-25', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'f3333333-3333-3333-3333-333333333333', null, 'Infrastructure'),
  ('ac444444-4444-4444-4444-444444444444', 'Update Environmental Compliance Guidelines', 'Revise guidelines to reflect new national environmental regulations', 'in_progress', 'medium', '2024-04-15', 'dddddddd-dddd-dddd-dddd-dddddddddddd', null, null, 'Environment'),
  ('ac555555-5555-5555-5555-555555555555', 'Review Public Participation Process', 'Evaluate current public participation procedures for development applications', 'pending', 'low', '2024-04-20', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', null, null, 'Development Planning');
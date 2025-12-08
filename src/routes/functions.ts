import express from 'express';
import { authenticate } from '../middleware/auth.js';
import { loadUserContext, getOrganizationFilter } from '../middleware/authorization.js';
import pool from '../config/database.js';

const router = express.Router();

// Apply authentication and user context to all function routes
router.use(authenticate);
router.use(loadUserContext);

// Onboarding Endpoint
router.post('/complete-user-onboarding', async (req, res) => {
  try {
    const {
      _user_id,
      _organization_name,
      _organization_domain,
      _first_name,
      _last_name
    } = req.body;

    if (!_user_id || !_organization_name || !_first_name || !_last_name) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // 1. Create Organization
    // Auto-generate slug from name if not provided (simple version)
    const slug = _organization_name.toLowerCase().replace(/[^a-z0-9]+/g, '-');

    const orgResult = await pool.query(
      `INSERT INTO organizations (name, slug, domain, subscription_status)
       VALUES ($1, $2, $3, 'active')
       ON CONFLICT (slug) DO UPDATE SET domain = $3
       RETURNING id`,
      [_organization_name, slug, _organization_domain]
    );

    const organizationId = orgResult.rows[0].id;

    // 2. Update Profile
    await pool.query(
      `UPDATE profiles 
       SET first_name = $1, 
           last_name = $2, 
           organization_id = $3
       WHERE user_id = $4`,
      [_first_name, _last_name, organizationId, _user_id]
    );

    // 3. Assign Admin Role
    await pool.query(
      `INSERT INTO user_roles (user_id, role)
       VALUES ($1, 'admin')
       ON CONFLICT (user_id, role, committee_id) DO NOTHING`,
      [_user_id]
    );

    res.json({ success: true, organization_id: organizationId });

  } catch (error: any) {
    console.error('Onboarding error:', error);
    res.status(500).json({ error: error.message });
  }
});

// AI Assistant endpoint
router.post('/ai-assistant', async (req, res) => {
  try {
    const { messages, userRole } = req.body;

    const LOVABLE_API_KEY = process.env.LOVABLE_API_KEY;
    if (!LOVABLE_API_KEY) {
      return res.status(500).json({ error: 'LOVABLE_API_KEY not configured' });
    }

    // Get user's committees and roles
    const userRolesResult = await pool.query(
      `SELECT role, committee_id FROM user_roles WHERE user_id = $1`,
      [req.user!.id]
    );

    const roles = userRolesResult.rows.map(r => r.role);
    const committeeIds = userRolesResult.rows
      .filter(r => r.committee_id)
      .map(r => r.committee_id);

    // Build context based on user's last message
    const lastMessage = messages[messages.length - 1]?.content || "";
    let context = "";

    // Search for relevant documents
    if (lastMessage.toLowerCase().includes('document') || lastMessage.toLowerCase().includes('report')) {
      const documentsResult = await pool.query(
        `SELECT md.id, md.title, md.document_type, md.created_at,
                m.title as meeting_title, m.meeting_date, m.committee_id,
                c.name as committee_name
         FROM meeting_documents md
         JOIN meetings m ON md.meeting_id = m.id
         JOIN committees c ON m.committee_id = c.id
         WHERE m.committee_id = ANY($1::uuid[])
         ORDER BY md.created_at DESC
         LIMIT 5`,
        [committeeIds.length > 0 ? committeeIds : ['00000000-0000-0000-0000-000000000000']]
      );

      if (documentsResult.rows.length > 0) {
        context += "\n\nRecent Documents:\n" + documentsResult.rows.map(d =>
          `- ${d.title} (${d.document_type}) from ${d.committee_name || 'Unknown Committee'} on ${new Date(d.meeting_date).toLocaleDateString()}`
        ).join('\n');
      }
    }

    // Search for action items
    if (lastMessage.toLowerCase().includes('action') || lastMessage.toLowerCase().includes('task')) {
      const actionsResult = await pool.query(
        `SELECT ai.id, ai.title, ai.status, ai.priority, ai.due_date, c.name as committee_name
         FROM action_items ai
         LEFT JOIN committees c ON ai.committee_id = c.id
         WHERE ai.committee_id = ANY($1::uuid[])
         ORDER BY ai.created_at DESC
         LIMIT 5`,
        [committeeIds.length > 0 ? committeeIds : ['00000000-0000-0000-0000-000000000000']]
      );

      if (actionsResult.rows.length > 0) {
        context += "\n\nRecent Action Items:\n" + actionsResult.rows.map(a =>
          `- ${a.title} (${a.status}, ${a.priority} priority) - Due: ${a.due_date ? new Date(a.due_date).toLocaleDateString() : 'Not set'} - Committee: ${a.committee_name || 'Unknown'}`
        ).join('\n');
      }
    }

    // Search for meetings
    if (lastMessage.toLowerCase().includes('meeting') || lastMessage.toLowerCase().includes('agenda')) {
      const meetingsResult = await pool.query(
        `SELECT m.id, m.title, m.meeting_date, m.status, c.name as committee_name
         FROM meetings m
         JOIN committees c ON m.committee_id = c.id
         WHERE m.committee_id = ANY($1::uuid[])
         ORDER BY m.meeting_date DESC
         LIMIT 5`,
        [committeeIds.length > 0 ? committeeIds : ['00000000-0000-0000-0000-000000000000']]
      );

      if (meetingsResult.rows.length > 0) {
        context += "\n\nRecent Meetings:\n" + meetingsResult.rows.map(m =>
          `- ${m.title} (${m.status}) on ${new Date(m.meeting_date).toLocaleDateString()} - Committee: ${m.committee_name || 'Unknown'}`
        ).join('\n');
      }
    }

    // Search for resolutions/motions
    if (lastMessage.toLowerCase().includes('resolution') || lastMessage.toLowerCase().includes('motion')) {
      const motionsResult = await pool.query(
        `SELECT m.id, m.title, m.motion_type, m.status, m.outcome, m.notice_date, c.name as committee_name
         FROM motions m
         LEFT JOIN committees c ON m.committee_id = c.id
         WHERE m.committee_id = ANY($1::uuid[])
         ORDER BY m.notice_date DESC
         LIMIT 5`,
        [committeeIds.length > 0 ? committeeIds : ['00000000-0000-0000-0000-000000000000']]
      );

      if (motionsResult.rows.length > 0) {
        context += "\n\nRecent Motions/Resolutions:\n" + motionsResult.rows.map(m =>
          `- ${m.title} (${m.motion_type}, ${m.status}) - Outcome: ${m.outcome || 'Pending'} - Committee: ${m.committee_name || 'Unknown'}`
        ).join('\n');
      }
    }

    const systemPrompt = `You are a helpful AI assistant for GRACE (Government Reporting And Committee Execution). 
You help users retrieve committee documents, previous resolutions, and agenda statuses.

User's Role: ${roles.join(', ') || 'No specific role'}
User has access to ${committeeIds.length} committee(s).

IMPORTANT: Only provide information from the context provided below. If information is not available in the context, politely inform the user that you don't have access to that information or that it wasn't found in recent records.

Available Context:${context || '\n\nNo specific records found for this query. The user may need to refine their search or check if they have access to the relevant committees.'}

Be concise, helpful, and professional. Format your responses clearly with bullet points when listing items.`;

    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          ...messages,
        ],
        stream: true,
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return res.status(429).json({ error: "Rate limits exceeded, please try again later." });
      }
      if (response.status === 402) {
        return res.status(402).json({ error: "Payment required, please add funds to your Lovable AI workspace." });
      }
      const errorText = await response.text();
      console.error("AI gateway error:", response.status, errorText);
      return res.status(500).json({ error: "AI gateway error" });
    }

    // Stream the response
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      res.write(chunk);
    }

    res.end();
  } catch (error: any) {
    console.error("AI assistant error:", error);
    res.status(500).json({ error: error.message || "Unknown error" });
  }
});

// Generate minutes endpoint
router.post('/generate-minutes', async (req, res) => {
  try {
    const { meetingId } = req.body;

    const LOVABLE_API_KEY = process.env.LOVABLE_API_KEY;
    if (!LOVABLE_API_KEY) {
      return res.status(500).json({ error: 'LOVABLE_API_KEY not configured' });
    }
    if (!meetingId) {
      return res.status(400).json({ error: 'meetingId is required' });
    }

    // Fetch meeting details with access control
    const orgFilter = getOrganizationFilter(req.userContext!);
    let meetingQuery = `
      SELECT m.id, m.title, m.meeting_date, m.venue, m.meeting_type, m.status,
             c.name as committee_name, c.type as committee_type, m.committee_id, m.organization_id
      FROM meetings m
      JOIN committees c ON m.committee_id = c.id
      WHERE m.id = $1
    `;
    const meetingParams: any[] = [meetingId];

    if (orgFilter) {
      meetingQuery += ` AND m.organization_id = $2`;
      meetingParams.push(orgFilter);
    }

    // Check committee access
    if (!req.userContext!.roles.includes('super_admin') && !req.userContext!.roles.includes('admin')) {
      if (req.userContext!.committeeIds.length > 0) {
        const placeholders = req.userContext!.committeeIds.map((_, i) => `$${meetingParams.length + i + 1}`).join(', ');
        meetingQuery += ` AND m.committee_id IN (${placeholders})`;
        meetingParams.push(...req.userContext!.committeeIds);
      } else {
        return res.status(403).json({ error: 'Access denied to this meeting' });
      }
    }

    const meetingResult = await pool.query(meetingQuery, meetingParams);

    if (meetingResult.rows.length === 0) {
      return res.status(404).json({ error: 'Meeting not found or access denied' });
    }

    const meeting = meetingResult.rows[0];

    // Fetch agenda items
    const agendaResult = await pool.query(
      `SELECT id, item_number, title, description, item_type, status, order_index, requires_vote, estimated_duration
       FROM agenda_items
       WHERE meeting_id = $1
       ORDER BY order_index ASC`,
      [meetingId]
    );

    // Fetch decisions
    const decisionsResult = await pool.query(
      `SELECT id, decision_number, decision_type, decision_text, owner_department, due_date, priority, status
       FROM decisions_register
       WHERE meeting_id = $1
       ORDER BY created_at ASC`,
      [meetingId]
    );

    // Fetch attendance
    const attendanceResult = await pool.query(
      `SELECT ma.id, ma.attendance_status, p.first_name, p.last_name
       FROM meeting_attendance ma
       JOIN profiles p ON ma.user_id = p.user_id
       WHERE ma.meeting_id = $1`,
      [meetingId]
    );

    // Build context
    const meetingContext = `
Meeting Details:
- Title: ${meeting.title}
- Committee: ${meeting.committee_name || 'Unknown Committee'} (${meeting.committee_type || 'Unknown Type'})
- Date: ${new Date(meeting.meeting_date).toLocaleString()}
- Venue: ${meeting.venue || 'Not specified'}
- Type: ${meeting.meeting_type}
- Status: ${meeting.status}

Attendance:
${attendanceResult.rows.length > 0
        ? attendanceResult.rows.map(a => `- ${a.first_name} ${a.last_name}: ${a.attendance_status}`).join('\n')
        : '- No attendance records available'}

Agenda Items:
${agendaResult.rows.length > 0
        ? agendaResult.rows.map(item => `
${item.item_number}. ${item.title}
   Type: ${item.item_type}
   Status: ${item.status}
   ${item.description ? `Description: ${item.description}` : ''}
   ${item.requires_vote ? 'Requires Vote: Yes' : ''}
   ${item.estimated_duration ? `Duration: ${item.estimated_duration} minutes` : ''}
`).join('\n')
        : '- No agenda items available'}

Decisions and Resolutions:
${decisionsResult.rows.length > 0
        ? decisionsResult.rows.map(d => `
${d.decision_number}. ${d.decision_type}
   Decision: ${d.decision_text}
   ${d.owner_department ? `Responsible: ${d.owner_department}` : ''}
   ${d.due_date ? `Due Date: ${new Date(d.due_date).toLocaleDateString()}` : ''}
   Priority: ${d.priority}
   Status: ${d.status}
`).join('\n')
        : '- No decisions recorded'}
`;

    const systemPrompt = `You are a professional minutes writer for municipal government meetings. 
Your task is to generate formal, well-structured meeting minutes based on the provided meeting information.

Guidelines:
1. Use formal, professional language appropriate for government records
2. Structure the minutes with clear sections: Meeting Details, Attendance, Agenda Items, Decisions, and Closing
3. For each agenda item, summarize the discussion and outcome
4. For decisions, clearly state the resolution number, decision text, responsible party, and deadlines
5. Be concise but comprehensive
6. Use proper formatting with headers, bullet points, and numbering
7. Include all relevant details from the context provided
8. Follow standard municipal meeting minutes format

Format the output as a clean, readable document that can be directly used as official minutes.`;

    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          {
            role: "user",
            content: `Generate professional meeting minutes based on the following information:\n\n${meetingContext}`
          },
        ],
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return res.status(429).json({ error: "Rate limits exceeded, please try again later." });
      }
      if (response.status === 402) {
        return res.status(402).json({ error: "Payment required, please add funds to your Lovable AI workspace." });
      }
      const errorText = await response.text();
      console.error("AI gateway error:", response.status, errorText);
      return res.status(500).json({ error: "AI gateway error" });
    }

    const data = await response.json() as any;
    const generatedMinutes = data.choices[0].message.content;

    res.json({ minutes: generatedMinutes });
  } catch (error: any) {
    console.error("Generate minutes error:", error);
    res.status(500).json({ error: error.message || "Unknown error" });
  }
});

// Teams notification endpoint
router.post('/teams-notify', async (req, res) => {
  try {
    const { organizationId, title, message, notificationType, metadata, themeColor } = req.body;

    // Get organization's Teams webhook URL
    const orgResult = await pool.query(
      'SELECT teams_webhook_url FROM organizations WHERE id = $1',
      [organizationId]
    );

    if (orgResult.rows.length === 0) {
      return res.status(404).json({ error: 'Organization not found' });
    }

    const org = orgResult.rows[0];

    if (!org.teams_webhook_url) {
      return res.status(400).json({ error: 'Teams webhook URL not configured for this organization' });
    }

    // Build Teams message card
    const card = {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      summary: title,
      themeColor: themeColor || "0078D4",
      title: title,
      sections: [
        {
          text: message,
          facts: metadata ? Object.entries(metadata).map(([key, value]) => ({
            name: key,
            value: String(value),
          })) : [],
        },
      ],
    };

    // Send notification to Teams
    const teamsResponse = await fetch(org.teams_webhook_url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(card),
    });

    const success = teamsResponse.ok;
    const errorMessage = success ? null : await teamsResponse.text();

    // Log notification to database
    await pool.query(
      `INSERT INTO teams_notifications (organization_id, notification_type, title, message, success, error_message, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [organizationId, notificationType, title, message, success, errorMessage, JSON.stringify(metadata || {})]
    );

    if (!success) {
      return res.status(500).json({ error: `Teams webhook error: ${errorMessage}` });
    }

    res.json({ success: true, message: "Notification sent successfully" });
  } catch (error: any) {
    console.error("Teams notification error:", error);
    res.status(500).json({ error: error.message || "Unknown error" });
  }
});

// Send notification email endpoint (without Resend - just logs to database)
router.post('/send-notification-email', async (req, res) => {
  try {
    const {
      organizationId,
      recipientEmail,
      recipientId,
      subject,
      title,
      message,
      notificationType,
      metadata = {},
    } = req.body;

    // Validate required fields
    if (!organizationId || !subject || !title || !message || !notificationType) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Determine recipient email
    let emailTo = recipientEmail;

    if (!emailTo && recipientId) {
      const profileResult = await pool.query(
        'SELECT email FROM profiles WHERE user_id = $1',
        [recipientId]
      );

      if (profileResult.rows.length === 0 || !profileResult.rows[0].email) {
        return res.status(404).json({ error: 'Could not find recipient email' });
      }

      emailTo = profileResult.rows[0].email;
    }

    if (!emailTo) {
      return res.status(400).json({ error: 'No recipient email provided' });
    }

    // Log the notification in database (email sending removed)
    await pool.query(
      `INSERT INTO email_notifications (organization_id, recipient_email, recipient_id, subject, notification_type, metadata, status, sent_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        organizationId,
        emailTo,
        recipientId,
        subject,
        notificationType,
        JSON.stringify(metadata),
        'logged', // Changed from 'sent' to 'logged' since we're not actually sending
        new Date().toISOString(),
      ]
    );

    res.json({
      success: true,
      message: "Email notification logged successfully (email sending disabled)",
    });
  } catch (error: any) {
    console.error("Error in send-notification-email function:", error);
    res.status(500).json({ error: error.message || "Unknown error" });
  }
});

// Health check endpoint
router.get('/health-check', async (req, res) => {
  try {
    // Check database connectivity
    await pool.query('SELECT 1');

    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      checks: {
        database: 'healthy',
        authentication: 'healthy',
        edgeFunctions: 'healthy'
      }
    });
  } catch (error: any) {
    console.error('Health check error:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      checks: {
        database: 'failed',
        error: error.message
      }
    });
  }
});

export default router;


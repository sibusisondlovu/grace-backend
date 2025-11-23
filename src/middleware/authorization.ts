import { Request, Response, NextFunction } from 'express';
import pool from '../config/database.js';

type AppRole = 'admin' | 'speaker' | 'chair' | 'deputy_chair' | 'whip' | 'member' | 'external_member' | 'coordinator' | 'clerk' | 'legal' | 'cfo' | 'public' | 'super_admin';

interface UserContext {
  id: string;
  email: string;
  organizationId?: string;
  roles: AppRole[];
  committeeIds: string[];
}

declare global {
  namespace Express {
    interface Request {
      userContext?: UserContext;
    }
  }
}

// Load user context (roles, organization, committees)
export const loadUserContext = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    // Get user profile with organization
    const profileResult = await pool.query(
      `SELECT organization_id FROM profiles WHERE user_id = $1`,
      [req.user.id]
    );

    const organizationId = profileResult.rows[0]?.organization_id || null;

    // Get user roles
    const rolesResult = await pool.query(
      `SELECT role, committee_id FROM user_roles WHERE user_id = $1`,
      [req.user.id]
    );

    const roles = rolesResult.rows.map(r => r.role) as AppRole[];
    const committeeIds = rolesResult.rows
      .filter(r => r.committee_id)
      .map(r => r.committee_id);

    // Get committee memberships
    const membershipsResult = await pool.query(
      `SELECT committee_id FROM committee_members 
       WHERE user_id = $1 AND (end_date IS NULL OR end_date >= CURRENT_DATE)`,
      [req.user.id]
    );

    const membershipCommitteeIds = membershipsResult.rows.map(r => r.committee_id);
    const allCommitteeIds = [...new Set([...committeeIds, ...membershipCommitteeIds])];

    req.userContext = {
      id: req.user.id,
      email: req.user.email,
      organizationId: organizationId || undefined,
      roles,
      committeeIds: allCommitteeIds,
    };

    next();
  } catch (error: any) {
    console.error('Error loading user context:', error);
    return res.status(500).json({ error: 'Failed to load user context' });
  }
};

// Check if user has a specific role
export const hasRole = (...requiredRoles: AppRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.userContext) {
      return res.status(401).json({ error: 'User context not loaded' });
    }

    const hasRequiredRole = requiredRoles.some(role => 
      req.userContext!.roles.includes(role)
    );

    if (!hasRequiredRole) {
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        required: requiredRoles,
        current: req.userContext.roles
      });
    }

    next();
  };
};

// Check if user is admin or super_admin
export const isAdmin = (req: Request, res: Response, next: NextFunction) => {
  if (!req.userContext) {
    return res.status(401).json({ error: 'User context not loaded' });
  }

  const isAdminUser = req.userContext.roles.includes('admin') || 
                      req.userContext.roles.includes('super_admin');

  if (!isAdminUser) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  next();
};

// Check if user has access to a specific organization
export const hasOrganizationAccess = (req: Request, res: Response, next: NextFunction) => {
  if (!req.userContext) {
    return res.status(401).json({ error: 'User context not loaded' });
  }

  // Super admins can access all organizations
  if (req.userContext.roles.includes('super_admin')) {
    return next();
  }

  // Admins can access their own organization
  if (req.userContext.roles.includes('admin')) {
    const requestedOrgId = req.params.organizationId || req.body.organization_id || req.query.organization_id;
    
    if (requestedOrgId && req.userContext.organizationId !== requestedOrgId) {
      return res.status(403).json({ error: 'Access denied to this organization' });
    }
  }

  next();
};

// Check if user has access to a specific committee
export const hasCommitteeAccess = async (
  committeeId: string,
  userId: string,
  userContext: UserContext
): Promise<boolean> => {
  // Super admins have access to all committees
  if (userContext.roles.includes('super_admin')) {
    return true;
  }

  // Admins have access to committees in their organization
  if (userContext.roles.includes('admin')) {
    const committeeResult = await pool.query(
      `SELECT organization_id FROM committees WHERE id = $1`,
      [committeeId]
    );

    if (committeeResult.rows.length === 0) {
      return false;
    }

    return committeeResult.rows[0].organization_id === userContext.organizationId;
  }

  // Check if user is a member of the committee
  if (userContext.committeeIds.includes(committeeId)) {
    return true;
  }

  // Check if user has a role for this committee
  const roleResult = await pool.query(
    `SELECT 1 FROM user_roles 
     WHERE user_id = $1 AND committee_id = $2`,
    [userId, committeeId]
  );

  return roleResult.rows.length > 0;
};

// Middleware to check committee access from request
export const checkCommitteeAccess = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.userContext) {
    return res.status(401).json({ error: 'User context not loaded' });
  }

  const committeeId = req.params.committeeId || req.body.committee_id || req.query.committee_id;

  if (!committeeId) {
    return next(); // No committee specified, let other checks handle it
  }

  const hasAccess = await hasCommitteeAccess(
    committeeId,
    req.userContext.id,
    req.userContext
  );

  if (!hasAccess) {
    return res.status(403).json({ error: 'Access denied to this committee' });
  }

  next();
};

// Helper function to get organization filter for queries
export const getOrganizationFilter = (userContext: UserContext): string | null => {
  // Super admins can see all organizations
  if (userContext.roles.includes('super_admin')) {
    return null;
  }

  // Regular users can only see their organization's data
  return userContext.organizationId || null;
};

// Helper function to get committee filter for queries
export const getCommitteeFilter = (userContext: UserContext): string[] | null => {
  // Super admins can see all committees
  if (userContext.roles.includes('super_admin')) {
    return null;
  }

  // Admins can see all committees in their organization
  if (userContext.roles.includes('admin')) {
    return null; // Will be filtered by organization_id
  }

  // Regular users can only see committees they're members of
  return userContext.committeeIds.length > 0 ? userContext.committeeIds : [];
};


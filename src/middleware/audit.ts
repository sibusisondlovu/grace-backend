import { Request } from 'express';
import pool from '../config/database.js';

export const auditLog = async (
  userId: string,
  action: string,
  tableName: string,
  recordId: string | null,
  changes?: Record<string, any>
) => {
  try {
    await pool.query(
      `INSERT INTO audit_logs (user_id, action, table_name, record_id, changes, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`,
      [userId, action, tableName, recordId, JSON.stringify(changes || {})]
    );
  } catch (error) {
    console.error('Audit log error:', error);
    // Don't fail the request if audit logging fails
  }
};

// Middleware to audit sensitive operations
export const auditMiddleware = (action: string) => {
  return async (req: Request, res: any, next: any) => {
    const originalJson = res.json.bind(res);
    
    res.json = function(data: any) {
      // Log after successful operation
      if (res.statusCode < 400 && req.userContext) {
        const recordId = req.params.id || req.body.id || data?.id || null;
        auditLog(
          req.userContext.id,
          action,
          req.params.table || 'unknown',
          recordId,
          req.method !== 'GET' ? req.body : undefined
        );
      }
      
      return originalJson(data);
    };
    
    next();
  };
};


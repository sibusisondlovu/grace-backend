import pool from '../config/database.js';
export const auditLog = async (userId, action, tableName, recordId, changes) => {
    try {
        await pool.query(`INSERT INTO audit_logs (user_id, action, table_name, record_id, changes, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`, [userId, action, tableName, recordId, JSON.stringify(changes || {})]);
    }
    catch (error) {
        console.error('Audit log error:', error);
        // Don't fail the request if audit logging fails
    }
};
// Middleware to audit sensitive operations
export const auditMiddleware = (action) => {
    return async (req, res, next) => {
        const originalJson = res.json.bind(res);
        res.json = function (data) {
            // Log after successful operation
            if (res.statusCode < 400 && req.userContext) {
                const recordId = req.params.id || req.body.id || data?.id || null;
                auditLog(req.userContext.id, action, req.params.table || 'unknown', recordId, req.method !== 'GET' ? req.body : undefined);
            }
            return originalJson(data);
        };
        next();
    };
};
//# sourceMappingURL=audit.js.map
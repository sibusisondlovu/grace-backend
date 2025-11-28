"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.auditMiddleware = exports.auditLog = void 0;
const database_js_1 = __importDefault(require("../config/database.js"));
const auditLog = async (userId, action, tableName, recordId, changes) => {
    try {
        await database_js_1.default.query(`INSERT INTO audit_logs (user_id, action, table_name, record_id, changes, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`, [userId, action, tableName, recordId, JSON.stringify(changes || {})]);
    }
    catch (error) {
        console.error('Audit log error:', error);
        // Don't fail the request if audit logging fails
    }
};
exports.auditLog = auditLog;
// Middleware to audit sensitive operations
const auditMiddleware = (action) => {
    return async (req, res, next) => {
        const originalJson = res.json.bind(res);
        res.json = function (data) {
            // Log after successful operation
            if (res.statusCode < 400 && req.userContext) {
                const recordId = req.params.id || req.body.id || data?.id || null;
                (0, exports.auditLog)(req.userContext.id, action, req.params.table || 'unknown', recordId, req.method !== 'GET' ? req.body : undefined);
            }
            return originalJson(data);
        };
        next();
    };
};
exports.auditMiddleware = auditMiddleware;
//# sourceMappingURL=audit.js.map
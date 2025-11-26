import express from 'express';
import { authenticate } from '../middleware/auth.js';
import { loadUserContext, getOrganizationFilter, getCommitteeFilter } from '../middleware/authorization.js';
import pool from '../config/database.js';
const router = express.Router();
// Apply authentication and user context loading to all routes
router.use(authenticate);
router.use(loadUserContext);
// SQL injection protection helper
function sanitizeTableName(table) {
    // Only allow alphanumeric and underscore, must start with letter or underscore
    if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(table)) {
        throw new Error('Invalid table name');
    }
    return table;
}
// Generic query handler
router.get('/:table', async (req, res) => {
    try {
        const { table } = req.params;
        const queryParams = req.query;
        const safeTable = sanitizeTableName(table);
        // Handle count query
        if (queryParams.count === 'exact' && queryParams.head === 'true') {
            let countQuery = `SELECT COUNT(*) as count FROM ${safeTable}`;
            const countValues = [];
            let countParamIndex = 1;
            const countConditions = [];
            // Apply filters for count
            Object.keys(queryParams).forEach(key => {
                if (['columns', 'order', 'ascending', 'limit', 'offset', 'single', 'count', 'head'].includes(key))
                    return;
                const value = queryParams[key];
                if (value !== undefined && value !== null && value !== '') {
                    if (key.endsWith('__gte')) {
                        const column = key.replace('__gte', '');
                        countConditions.push(`${column} >= $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                    else if (key.endsWith('__lte')) {
                        const column = key.replace('__lte', '');
                        countConditions.push(`${column} <= $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                    else if (key.endsWith('__gt')) {
                        const column = key.replace('__gt', '');
                        countConditions.push(`${column} > $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                    else if (key.endsWith('__lt')) {
                        const column = key.replace('__lt', '');
                        countConditions.push(`${column} < $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                    else if (key.endsWith('__neq')) {
                        const column = key.replace('__neq', '');
                        countConditions.push(`${column} != $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                    else if (key.endsWith('__in')) {
                        const column = key.replace('__in', '');
                        const inValues = String(value).split(',').map(v => v.trim());
                        const placeholders = inValues.map((_, i) => `$${countParamIndex + i}`).join(', ');
                        countConditions.push(`${column} IN (${placeholders})`);
                        countValues.push(...inValues);
                        countParamIndex += inValues.length;
                    }
                    else {
                        countConditions.push(`${key} = $${countParamIndex}`);
                        countValues.push(value);
                        countParamIndex++;
                    }
                }
            });
            if (countConditions.length > 0) {
                countQuery += ' WHERE ' + countConditions.join(' AND ');
            }
            const countResult = await pool.query(countQuery, countValues);
            return res.json({ count: parseInt(countResult.rows[0].count) });
        }
        let query = `SELECT * FROM ${safeTable}`;
        const values = [];
        let paramIndex = 1;
        const conditions = [];
        // Handle filters (eq, gte, lte, etc.)
        Object.keys(queryParams).forEach(key => {
            if (key === 'columns' || key === 'order' || key === 'ascending' || key === 'limit' || key === 'offset' || key === 'single' || key === 'count' || key === 'head')
                return;
            const value = queryParams[key];
            if (value !== undefined && value !== null && value !== '') {
                if (key.endsWith('__gte')) {
                    const column = key.replace('__gte', '');
                    conditions.push(`${column} >= $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else if (key.endsWith('__lte')) {
                    const column = key.replace('__lte', '');
                    conditions.push(`${column} <= $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else if (key.endsWith('__gt')) {
                    const column = key.replace('__gt', '');
                    conditions.push(`${column} > $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else if (key.endsWith('__lt')) {
                    const column = key.replace('__lt', '');
                    conditions.push(`${column} < $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else if (key.endsWith('__neq')) {
                    const column = key.replace('__neq', '');
                    conditions.push(`${column} != $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else if (key.endsWith('__in')) {
                    const column = key.replace('__in', '');
                    const inValues = String(value).split(',').map(v => v.trim());
                    const placeholders = inValues.map((_, i) => `$${paramIndex + i}`).join(', ');
                    conditions.push(`${column} IN (${placeholders})`);
                    values.push(...inValues);
                    paramIndex += inValues.length;
                }
                else if (key.endsWith('__like')) {
                    const column = key.replace('__like', '');
                    conditions.push(`${column} LIKE $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
                else {
                    conditions.push(`${key} = $${paramIndex}`);
                    values.push(value);
                    paramIndex++;
                }
            }
        });
        // Apply organization-level data segregation
        const orgFilter = getOrganizationFilter(req.userContext);
        if (orgFilter && safeTable !== 'organizations') {
            // Check if table has organization_id column
            const hasOrgColumn = await pool.query(`SELECT column_name FROM information_schema.columns 
         WHERE table_name = $1 AND column_name = 'organization_id'`, [safeTable]);
            if (hasOrgColumn.rows.length > 0) {
                conditions.push(`organization_id = $${paramIndex}`);
                values.push(orgFilter);
                paramIndex++;
            }
        }
        // Apply committee-level access control for committee-related tables
        if (['meetings', 'agenda_items', 'action_items', 'committee_members'].includes(safeTable)) {
            const committeeFilter = getCommitteeFilter(req.userContext);
            if (committeeFilter && committeeFilter.length > 0) {
                const placeholders = committeeFilter.map((_, i) => `$${paramIndex + i}`).join(', ');
                conditions.push(`committee_id IN (${placeholders})`);
                values.push(...committeeFilter);
                paramIndex += committeeFilter.length;
            }
            else if (committeeFilter && committeeFilter.length === 0) {
                // User has no committee access, return empty result
                return res.json([]);
            }
        }
        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        // Handle ordering
        if (queryParams.order) {
            const orderBy = queryParams.order;
            const ascending = queryParams.ascending !== 'false';
            query += ` ORDER BY ${orderBy} ${ascending ? 'ASC' : 'DESC'}`;
        }
        // Handle offset
        if (queryParams.offset) {
            query += ` OFFSET $${paramIndex}`;
            values.push(parseInt(queryParams.offset));
            paramIndex++;
        }
        // Handle limit
        if (queryParams.limit) {
            query += ` LIMIT $${paramIndex}`;
            values.push(parseInt(queryParams.limit));
        }
        const result = await pool.query(query, values);
        const data = queryParams.single === 'true' && result.rows.length > 0 ? result.rows[0] : result.rows;
        res.json(data);
    }
    catch (error) {
        console.error('Query error:', error);
        res.status(500).json({ error: error.message });
    }
});
// Insert
router.post('/:table', async (req, res) => {
    try {
        const { table } = req.params;
        const data = req.body;
        const safeTable = sanitizeTableName(table);
        const isArray = Array.isArray(data);
        const items = isArray ? data : [data];
        const results = [];
        for (const item of items) {
            // Enforce organization_id for multi-tenant tables
            const orgFilter = getOrganizationFilter(req.userContext);
            if (orgFilter && safeTable !== 'organizations' && !item.organization_id) {
                // Check if table has organization_id column
                const hasOrgColumn = await pool.query(`SELECT column_name FROM information_schema.columns 
           WHERE table_name = $1 AND column_name = 'organization_id'`, [safeTable]);
                if (hasOrgColumn.rows.length > 0) {
                    item.organization_id = orgFilter;
                }
            }
            // Verify committee access for committee-related inserts
            if (['meetings', 'agenda_items', 'action_items', 'committee_members'].includes(safeTable) && item.committee_id) {
                const { hasCommitteeAccess } = await import('../middleware/authorization.js');
                const hasAccess = await hasCommitteeAccess(item.committee_id, req.userContext.id, req.userContext);
                if (!hasAccess) {
                    return res.status(403).json({
                        error: 'Access denied to this committee',
                        committee_id: item.committee_id
                    });
                }
            }
            // Restrict certain operations to admins
            if (['user_roles', 'organizations', 'committees'].includes(safeTable)) {
                if (!req.userContext.roles.includes('admin') && !req.userContext.roles.includes('super_admin')) {
                    return res.status(403).json({ error: 'Admin access required for this operation' });
                }
            }
            const columns = Object.keys(item);
            const values = Object.values(item);
            const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
            const query = `
        INSERT INTO ${safeTable} (${columns.join(', ')})
        VALUES (${placeholders})
        RETURNING *
      `;
            const result = await pool.query(query, values);
            results.push(result.rows[0]);
        }
        res.json(isArray ? results : results[0]);
    }
    catch (error) {
        console.error('Insert error:', error);
        res.status(500).json({ error: error.message });
    }
});
// Update
router.patch('/:table', async (req, res) => {
    try {
        const { table } = req.params;
        const queryParams = req.query;
        const data = req.body;
        const safeTable = sanitizeTableName(table);
        const updateColumns = Object.keys(data);
        const updateValues = Object.values(data);
        const setClause = updateColumns.map((col, i) => `${col} = $${i + 1}`).join(', ');
        let paramIndex = updateColumns.length + 1;
        const conditions = [];
        Object.keys(queryParams).forEach(key => {
            const value = queryParams[key];
            if (value) {
                conditions.push(`${key} = $${paramIndex}`);
                updateValues.push(value);
                paramIndex++;
            }
        });
        if (conditions.length === 0) {
            return res.status(400).json({ error: 'Update requires WHERE conditions' });
        }
        // Apply organization filter for multi-tenant tables
        const orgFilter = getOrganizationFilter(req.userContext);
        if (orgFilter && safeTable !== 'organizations') {
            const hasOrgColumn = await pool.query(`SELECT column_name FROM information_schema.columns 
         WHERE table_name = $1 AND column_name = 'organization_id'`, [safeTable]);
            if (hasOrgColumn.rows.length > 0) {
                conditions.push(`organization_id = $${paramIndex}`);
                updateValues.push(orgFilter);
                paramIndex++;
            }
        }
        // Restrict certain operations to admins
        if (['user_roles', 'organizations', 'committees'].includes(safeTable)) {
            if (!req.userContext.roles.includes('admin') && !req.userContext.roles.includes('super_admin')) {
                return res.status(403).json({ error: 'Admin access required for this operation' });
            }
        }
        const query = `
      UPDATE ${safeTable}
      SET ${setClause}
      WHERE ${conditions.join(' AND ')}
      RETURNING *
    `;
        const result = await pool.query(query, updateValues);
        // Verify user has access to updated records
        if (result.rows.length > 0 && orgFilter) {
            const updatedOrgId = result.rows[0].organization_id;
            if (updatedOrgId && updatedOrgId !== orgFilter && !req.userContext.roles.includes('super_admin')) {
                return res.status(403).json({ error: 'Access denied to this record' });
            }
        }
        res.json(result.rows[0] || result.rows);
    }
    catch (error) {
        console.error('Update error:', error);
        res.status(500).json({ error: error.message });
    }
});
// Delete
router.delete('/:table', async (req, res) => {
    try {
        const { table } = req.params;
        const queryParams = req.query;
        const safeTable = sanitizeTableName(table);
        const values = [];
        let paramIndex = 1;
        const conditions = [];
        Object.keys(queryParams).forEach(key => {
            const value = queryParams[key];
            if (value) {
                conditions.push(`${key} = $${paramIndex}`);
                values.push(value);
                paramIndex++;
            }
        });
        if (conditions.length === 0) {
            return res.status(400).json({ error: 'Delete requires WHERE conditions' });
        }
        // Apply organization filter for multi-tenant tables
        const orgFilter = getOrganizationFilter(req.userContext);
        if (orgFilter && safeTable !== 'organizations') {
            const hasOrgColumn = await pool.query(`SELECT column_name FROM information_schema.columns 
         WHERE table_name = $1 AND column_name = 'organization_id'`, [safeTable]);
            if (hasOrgColumn.rows.length > 0) {
                conditions.push(`organization_id = $${paramIndex}`);
                values.push(orgFilter);
                paramIndex++;
            }
        }
        // Restrict certain operations to admins
        if (['user_roles', 'organizations', 'committees', 'users', 'profiles'].includes(safeTable)) {
            if (!req.userContext.roles.includes('admin') && !req.userContext.roles.includes('super_admin')) {
                return res.status(403).json({ error: 'Admin access required for this operation' });
            }
        }
        // First check what will be deleted to verify access
        const checkQuery = `SELECT * FROM ${safeTable} WHERE ${conditions.join(' AND ')}`;
        const checkResult = await pool.query(checkQuery, values);
        // Verify user has access to records being deleted
        if (checkResult.rows.length > 0 && orgFilter) {
            for (const row of checkResult.rows) {
                if (row.organization_id && row.organization_id !== orgFilter && !req.userContext.roles.includes('super_admin')) {
                    return res.status(403).json({ error: 'Access denied to one or more records' });
                }
            }
        }
        const query = `DELETE FROM ${safeTable} WHERE ${conditions.join(' AND ')} RETURNING *`;
        const result = await pool.query(query, values);
        res.json(result.rows);
    }
    catch (error) {
        console.error('Delete error:', error);
        res.status(500).json({ error: error.message });
    }
});
export default router;
//# sourceMappingURL=api.js.map
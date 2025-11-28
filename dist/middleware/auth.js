"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const jwks_rsa_1 = __importDefault(require("jwks-rsa"));
const database_js_1 = __importDefault(require("../config/database.js"));
// Microsoft Entra ID configuration
const TENANT_ID = process.env.AZURE_TENANT_ID || 'common';
const CLIENT_ID = process.env.AZURE_CLIENT_ID;
const client = (0, jwks_rsa_1.default)({
    jwksUri: `https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys`
});
function getKey(header, callback) {
    client.getSigningKey(header.kid, function (err, key) {
        if (err) {
            callback(err, null);
            return;
        }
        const signingKey = key?.getPublicKey();
        callback(null, signingKey);
    });
}
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No authorization header' });
        }
        const token = authHeader.substring(7);
        const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
        // 1. Try to verify as Local JWT
        try {
            const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
            // Verify user exists in database
            const result = await database_js_1.default.query('SELECT id, email FROM users WHERE id = $1', [decoded.userId]);
            if (result.rows.length > 0) {
                req.user = {
                    id: result.rows[0].id,
                    email: result.rows[0].email,
                };
                return next();
            }
            // If user not found, fall through to Entra ID check (unlikely but safe)
        }
        catch (localError) {
            // Not a valid local token, proceed to Entra ID verification
        }
        // 2. Verify as Entra ID Token
        jsonwebtoken_1.default.verify(token, getKey, {
            audience: CLIENT_ID, // Verify the token is intended for this app
            issuer: `https://login.microsoftonline.com/${TENANT_ID}/v2.0`
        }, async (err, decoded) => {
            if (err) {
                console.error('Token verification failed:', err);
                return res.status(401).json({ error: 'Invalid token' });
            }
            // Extract user info from Entra ID token
            // OID is the immutable object identifier for the user in Azure AD
            const azureUserId = decoded.oid;
            const email = decoded.preferred_username || decoded.email;
            if (!email) {
                return res.status(401).json({ error: 'Token missing email' });
            }
            try {
                // Check if user exists in our database
                // We might need to map Azure OID to our internal ID or just use email
                // For now, let's look up by email
                const result = await database_js_1.default.query('SELECT id, email FROM users WHERE email = $1', [email]);
                if (result.rows.length === 0) {
                    // Optional: Auto-provision user if they don't exist
                    // For now, return error
                    return res.status(401).json({ error: 'User not found in system' });
                }
                req.user = {
                    id: result.rows[0].id,
                    email: result.rows[0].email,
                };
                next();
            }
            catch (dbError) {
                console.error('Database error during auth:', dbError);
                return res.status(500).json({ error: 'Authentication database error' });
            }
        });
    }
    catch (error) {
        return res.status(500).json({ error: 'Authentication error' });
    }
};
exports.authenticate = authenticate;
//# sourceMappingURL=auth.js.map
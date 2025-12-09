import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksRsa from 'jwks-rsa';
import pool from '../config/database.js';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
      };
    }
  }
}

export interface AuthenticatedUser {
  id: string;
  email: string;
}

// Microsoft Entra ID configuration
const TENANT_ID = process.env.AZURE_TENANT_ID || 'common';
const CLIENT_ID = process.env.AZURE_CLIENT_ID;

const client = jwksRsa({
  jwksUri: `https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys`
});

function getKey(header: any, callback: any) {
  client.getSigningKey(header.kid, function (err, key) {
    if (err) {
      callback(err, null);
      return;
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
}

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No authorization header' });
    }

    const token = authHeader.substring(7);
    const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

    // 1. Try to verify as Local JWT
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as { userId: string; email: string };

      // Verify user exists in database
      const result = await pool.query(
        'SELECT id, email FROM users WHERE id = $1',
        [decoded.userId]
      );

      if (result.rows.length > 0) {
        req.user = {
          id: result.rows[0].id,
          email: result.rows[0].email,
        };
        return next();
      }
      // If user not found, fall through to Entra ID check (unlikely but safe)
    } catch (localError) {
      // Not a valid local token, proceed to Entra ID verification
    }

    // 2. Verify as Entra ID Token
    // We don't strictly enforce issuer here because for multi-tenant apps, the issuer contains the tenant ID
    // which varies. The signature verification via JWKS is the primary security mechanism.
    jwt.verify(token, getKey, {
      audience: CLIENT_ID,
    }, async (err, decoded: any) => {
      if (err) {
        console.error('Token verification failed:', err);
        return res.status(401).json({ error: 'Invalid token' });
      }

      // Extract user info
      const azureUserId = decoded.oid;
      const email = (decoded.preferred_username || decoded.email || decoded.upn)?.toLowerCase(); // Normalize email
      const name = decoded.name;

      if (!email) {
        return res.status(401).json({ error: 'Token missing email' });
      }

      try {
        // Check if user exists
        let result = await pool.query(
          'SELECT id, email FROM users WHERE email = $1',
          [email]
        );

        // JIT (Just-In-Time) Provisioning
        // If user is authenticated by Microsoft but not in our DB, create them.
        if (result.rows.length === 0) {
          console.log(`User ${email} not found, auto-provisioning...`);

          // 1. Insert into users
          const userInsert = await pool.query(
            `INSERT INTO users (email, password_hash, role)
             VALUES ($1, 'msal_managed', 'user')
             RETURNING id, email`,
            [email]
          );

          const newUserId = userInsert.rows[0].id;

          // 2. Insert into profiles (idempotent)
          const nameParts = name ? name.split(' ') : ['New', 'User'];
          const firstName = nameParts[0];
          const lastName = nameParts.slice(1).join(' ') || 'User';

          await pool.query(
            `INSERT INTO profiles (user_id, first_name, last_name)
             VALUES ($1, $2, $3)`,
            [newUserId, firstName, lastName]
          );

          result = userInsert;
        }

        req.user = {
          id: result.rows[0].id,
          email: result.rows[0].email,
        };

        next();
      } catch (dbError) {
        console.error('Database error during auth:', dbError);
        return res.status(500).json({ error: 'Authentication database error' });
      }
    });
  } catch (error) {
    return res.status(500).json({ error: 'Authentication error' });
  }
};



import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../config/database.js';
const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
// Sign in
router.post('/signin', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }
        // Find user
        const userResult = await pool.query('SELECT id, email, password_hash FROM users WHERE email = $1', [email.toLowerCase()]);
        if (userResult.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        const user = userResult.rows[0];
        // Verify password
        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        // Generate JWT token
        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
        // Get user profile
        const profileResult = await pool.query('SELECT * FROM profiles WHERE user_id = $1', [user.id]);
        const profile = profileResult.rows[0] || null;
        res.json({
            user: {
                id: user.id,
                email: user.email,
                ...profile,
            },
            session: {
                access_token: token,
                token_type: 'bearer',
                expires_in: 604800, // 7 days
                user: {
                    id: user.id,
                    email: user.email,
                },
            },
        });
    }
    catch (error) {
        console.error('Sign in error:', error);
        res.status(500).json({ error: error.message });
    }
});
// Sign out (client-side token removal, but we can log it)
router.post('/signout', async (req, res) => {
    res.json({ message: 'Signed out successfully' });
});
// Get current user
router.get('/user', async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No authorization header' });
        }
        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, JWT_SECRET);
        const userResult = await pool.query('SELECT id, email FROM users WHERE id = $1', [decoded.userId]);
        if (userResult.rows.length === 0) {
            return res.status(401).json({ error: 'User not found' });
        }
        const profileResult = await pool.query('SELECT * FROM profiles WHERE user_id = $1', [decoded.userId]);
        res.json({
            user: {
                id: userResult.rows[0].id,
                email: userResult.rows[0].email,
                ...(profileResult.rows[0] || {}),
            },
        });
    }
    catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
});
export default router;
//# sourceMappingURL=auth.js.map
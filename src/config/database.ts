import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'grace_db',
  user: process.env.DB_USER || 'grace_user',
  password: process.env.DB_PASSWORD || 'grace_password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

// Prevent unhandled errors from crashing the app
pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
});

export default pool;



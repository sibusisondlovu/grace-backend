"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const pg_1 = __importDefault(require("pg"));
const { Pool } = pg_1.default;
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'grace_db',
    user: process.env.DB_USER || 'grace_user',
    password: process.env.DB_PASSWORD || 'grace_password',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
    ssl: false
});
// Prevent unhandled errors from crashing the app
pool.on('error', (err) => {
    console.error('Unexpected database error:', err);
});
exports.default = pool;
//# sourceMappingURL=database.js.map
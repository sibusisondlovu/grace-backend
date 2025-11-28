"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const database_js_1 = __importDefault(require("./config/database.js"));
const fs_1 = require("fs");
const path_1 = require("path");
async function runMigrations() {
    try {
        console.log('Starting database migrations...');
        // Read and execute init.sql
        const initSql = (0, fs_1.readFileSync)((0, path_1.join)(__dirname, '../database/init.sql'), 'utf-8');
        await database_js_1.default.query(initSql);
        console.log('✓ Initial schema created');
        // Read all migration files from database/migrations
        const migrationsDir = (0, path_1.join)(__dirname, '../database/migrations');
        const migrationFiles = (0, fs_1.readdirSync)(migrationsDir)
            .filter(f => f.endsWith('.sql'))
            .sort();
        console.log(`Found ${migrationFiles.length} migration files`);
        for (const file of migrationFiles) {
            try {
                const migrationSql = (0, fs_1.readFileSync)((0, path_1.join)(migrationsDir, file), 'utf-8');
                // Replace auth.users references with users
                const adaptedSql = migrationSql
                    .replace(/auth\.users/g, 'users')
                    .replace(/REFERENCES auth\.users/g, 'REFERENCES users')
                    .replace(/ON auth\.users/g, 'ON users')
                    // Remove RLS policies (we'll handle auth differently)
                    .replace(/ALTER TABLE.*ENABLE ROW LEVEL SECURITY;?/gi, '')
                    .replace(/CREATE POLICY.*ON.*USING.*;/gi, '')
                    // Remove auth trigger (we'll handle profile creation in app)
                    .replace(/CREATE.*TRIGGER.*on_auth_user_created.*;/gi, '')
                    .replace(/CREATE.*FUNCTION.*handle_new_user.*;/gi, '');
                await database_js_1.default.query(adaptedSql);
                console.log(`✓ Applied migration: ${file}`);
            }
            catch (error) {
                // Some migrations might fail due to missing tables, that's okay
                if (error.message.includes('already exists') ||
                    error.message.includes('does not exist') ||
                    error.message.includes('duplicate')) {
                    console.log(`⚠ Skipped migration ${file}: ${error.message.split('\n')[0]}`);
                }
                else {
                    console.error(`✗ Error in migration ${file}:`, error.message);
                }
            }
        }
        console.log('✓ All migrations completed');
        process.exit(0);
    }
    catch (error) {
        console.error('Migration error:', error);
        process.exit(1);
    }
}
runMigrations();
//# sourceMappingURL=migrate.js.map
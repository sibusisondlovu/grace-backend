"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const auth_js_1 = __importDefault(require("./routes/auth.js"));
const functions_js_1 = __importDefault(require("./routes/functions.js"));
const api_js_1 = __importDefault(require("./routes/api.js"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3001;
// Middleware
const allowedOrigins = process.env.FRONTEND_URL
    ? [process.env.FRONTEND_URL]
    : ['http://localhost:5173', 'http://localhost:8080'];
app.use((0, cors_1.default)({
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin)
            return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        }
        else {
            callback(null, true); // Allow all origins in development
        }
    },
    credentials: true,
}));
app.use(express_1.default.json());
// Root route
app.get('/', (req, res) => {
    res.json({
        message: 'GRACE Backend API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            auth: '/auth',
            functions: '/functions/v1',
            api: '/api'
        }
    });
});
// Routes
app.use('/auth', auth_js_1.default);
app.use('/functions/v1', functions_js_1.default);
app.use('/api', api_js_1.default);
// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
//# sourceMappingURL=index.js.map
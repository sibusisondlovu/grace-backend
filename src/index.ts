import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import functionRoutes from './routes/functions.js';
import apiRoutes from './routes/api.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
const allowedOrigins = process.env.FRONTEND_URL
  ? [process.env.FRONTEND_URL]
  : ['http://localhost:5173', 'http://localhost:8080'];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true); // Allow all origins in development
    }
  },
  credentials: true,
}));
app.use(express.json());

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

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Routes
app.use('/auth', authRoutes);
app.use('/functions/v1', functionRoutes);
app.use('/api', apiRoutes);

// Serve static files from the React frontend app
const clientBuildPath = join(__dirname, 'client');
app.use(express.static(clientBuildPath));



// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Anything that doesn't match the above, send back index.html
app.get('*', (req, res) => {
  res.sendFile(join(clientBuildPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


# GRACE Backend Server

Backend API server for GRACE (Government Reporting And Committee Execution) - a comprehensive committee management and governance platform.

## Overview

This Node.js/Express backend provides REST APIs for committee management, meeting scheduling, document handling, and governance workflows. It integrates with PostgreSQL for data persistence and supports both traditional email/password authentication and Microsoft Entra ID (Azure AD) authentication.

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT + Microsoft Entra ID (MSAL)
- **Deployment**: Azure App Service (Windows/IIS)

## Prerequisites

- Node.js 20.x or higher
- PostgreSQL 14.x or higher
- npm or yarn

## Environment Variables

Create a `.env` file in the server root with the following variables:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/grace_db

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=7d

# Frontend URL (for CORS)
FRONTEND_URL=https://your-frontend-url.com

# Azure AD (Optional - for Microsoft authentication)
AZURE_AD_CLIENT_ID=your-client-id
AZURE_AD_TENANT_ID=your-tenant-id
AZURE_AD_CLIENT_SECRET=your-client-secret

# AI Features (Optional)
LOVABLE_API_KEY=your-lovable-api-key
```

## Installation

```bash
# Install dependencies
npm install

# Run database migrations
npm run migrate

# Build TypeScript
npm run build
```

## Development

```bash
# Run in development mode with hot reload
npm run dev
```

The server will start on `http://localhost:3001` by default.

## Production

```bash
# Build the project
npm run build

# Start the server
npm start
```

## API Endpoints

### Authentication
- `POST /auth/signin` - Email/password login
- `POST /auth/signout` - Logout
- `GET /auth/user` - Get current user (requires auth)

### Health Check
- `GET /health` - Basic health check
- `GET /functions/v1/health-check` - Detailed health check with database status

### Generic API (requires authentication)
- `GET /api/:table` - Query any table with filters
- `POST /api/:table` - Insert records
- `PATCH /api/:table` - Update records
- `DELETE /api/:table` - Delete records

### Functions (requires authentication)
- `POST /functions/v1/ai-assistant` - AI-powered assistant
- `POST /functions/v1/generate-minutes` - Generate meeting minutes
- `POST /functions/v1/teams-notify` - Send Teams notifications
- `POST /functions/v1/send-notification-email` - Send email notifications

## Database Schema

The database includes tables for:
- Users and profiles
- Organizations (multi-tenant)
- Committees and members
- Meetings and attendance
- Agenda items and decisions
- Action items and tracking
- Documents and storage
- Audit logs

Run migrations to set up the schema:
```bash
npm run migrate
```

## Security Features

- **Multi-tenancy**: Organization-level data isolation
- **RBAC**: Role-based access control
- **Row-Level Security**: Database-level access control
- **JWT Authentication**: Secure token-based auth
- **CORS**: Configurable cross-origin policies
- **Audit Logging**: Comprehensive activity tracking

## Azure Deployment

This backend is configured for Azure App Service deployment:

1. **web.config**: IIS configuration for Node.js
2. **postinstall script**: Automatically builds TypeScript on deployment
3. **Environment variables**: Configure in Azure Portal → Configuration

### Deployment Steps

1. Push code to GitHub repository
2. Configure Azure App Service to deploy from GitHub
3. Set environment variables in Azure Portal
4. Azure will automatically:
   - Install dependencies
   - Run `npm run build` (via postinstall)
   - Start the server with `npm start`

## Testing

Test the API endpoints:

```bash
# Health check
curl https://your-backend-url.azurewebsites.net/health

# Login
curl -X POST https://your-backend-url.azurewebsites.net/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'
```

## Project Structure

```
server/
├── src/
│   ├── config/
│   │   └── database.ts          # Database connection
│   ├── middleware/
│   │   ├── auth.ts              # JWT authentication
│   │   ├── authorization.ts     # RBAC & access control
│   │   └── audit.ts             # Audit logging
│   ├── routes/
│   │   ├── auth.ts              # Authentication routes
│   │   ├── api.ts               # Generic CRUD routes
│   │   └── functions.ts         # Function routes
│   ├── index.ts                 # Server entry point
│   └── migrate.ts               # Database migrations
├── web.config                   # IIS configuration
├── package.json
├── tsconfig.json
└── README.md
```

## License

Proprietary - GRACE Platform

## Support

For issues or questions, contact: support@grace.gov.za

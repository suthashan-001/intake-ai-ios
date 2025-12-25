# IntakeAI Backend API

Production-ready Node.js/Express backend for the IntakeAI healthcare application.

## Features

- **Authentication**: JWT-based auth with HttpOnly cookies and token rotation
- **Patient Management**: Full CRUD operations for patient records
- **Intake System**: Secure intake links with form submission
- **AI Summaries**: Google Gemini integration for clinical summary generation
- **Red Flag Detection**: Automatic detection of concerning symptoms
- **Error Tracking**: Sentry integration for production monitoring

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- Google Gemini API key (for AI features)

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your settings
nano .env

# Generate Prisma client
npm run db:generate

# Push database schema
npm run db:push

# Start development server
npm run dev
```

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout user |
| GET | `/api/auth/me` | Get current user |

### Patients

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/patients` | List patients |
| GET | `/api/patients/stats` | Dashboard statistics |
| GET | `/api/patients/:id` | Get patient |
| POST | `/api/patients` | Create patient |
| PUT | `/api/patients/:id` | Update patient |
| DELETE | `/api/patients/:id` | Delete patient |

### Intake Links

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/intake-links` | Create intake link |
| GET | `/api/intake-links/:token` | Get link info (public) |
| POST | `/api/intake-links/:token/submit` | Submit intake (public) |

### Intakes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/intakes` | List intakes |
| GET | `/api/intakes/:id` | Get intake details |
| POST | `/api/intakes/:id/review` | Mark as reviewed |

### AI Summaries

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/summaries` | List summaries |
| GET | `/api/summaries/:id` | Get summary |
| POST | `/api/summaries/generate` | Generate AI summary |
| POST | `/api/summaries/generate/stream` | Generate with SSE streaming |
| DELETE | `/api/summaries/:id` | Delete summary |

## Environment Variables

```bash
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/intakeai"

# JWT
JWT_ACCESS_SECRET="your-access-secret"
JWT_REFRESH_SECRET="your-refresh-secret"
ACCESS_TOKEN_EXPIRY="15m"
REFRESH_TOKEN_EXPIRY="7d"

# Gemini AI
GEMINI_API_KEY="your-gemini-key"

# Sentry (optional)
SENTRY_DSN=""

# Server
PORT=3001
NODE_ENV="development"
CORS_ORIGIN="http://localhost:3000"
```

## Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm run test -- --coverage

# Watch mode
npm run test:watch
```

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration
│   ├── controllers/     # Route handlers
│   ├── middleware/      # Express middleware
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── utils/           # Utilities
│   └── index.js         # App entry point
├── prisma/
│   └── schema.prisma    # Database schema
├── tests/               # Test files
└── package.json
```

## Security Features

- HttpOnly cookies for token storage
- Rate limiting on auth endpoints
- Helmet.js security headers
- CORS configuration
- Input validation with express-validator
- Password hashing with bcrypt (12 rounds)
- Token rotation on refresh

## Production Deployment

1. Set `NODE_ENV=production`
2. Use secure `JWT_*` secrets (generate with `openssl rand -base64 64`)
3. Configure Sentry DSN for error tracking
4. Set up PostgreSQL with SSL
5. Configure proper CORS origins
6. Use a reverse proxy (nginx) with HTTPS

## License

Private - All rights reserved

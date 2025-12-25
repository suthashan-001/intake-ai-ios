# IntakeAI

> A healthcare patient intake management system with AI-powered clinical summaries.

**Native iOS app + Node.js backend for healthcare providers to digitize patient intake forms and generate intelligent clinical summaries using AI.**

---

## Table of Contents

- [What Is This App?](#what-is-this-app)
- [For Web Developers: The Translation Guide](#for-web-developers-the-translation-guide)
- [Project Architecture](#project-architecture)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Key Files Reference](#key-files-reference)
- [API Documentation](#api-documentation)
- [Database Schema](#database-schema)
- [Design System](#design-system)
- [For LLMs: Context & Instructions](#for-llms-context--instructions)
- [Documentation](#documentation)
- [Tech Stack](#tech-stack)

---

## What Is This App?

IntakeAI solves a real problem in healthcare: **doctors waste 15-30 minutes per patient on paperwork**.

### The Problem
- Paper intake forms are slow, error-prone, and hard to read
- Manual data entry into EHR systems is time-consuming
- Important symptoms can be missed in rushed reviews
- Clinical notes take forever to write

### The Solution
1. **Digital Intake Forms**: Send patients a link to complete their intake before the appointment
2. **AI-Powered Summaries**: Google Gemini generates clinical summaries from intake data
3. **Red Flag Detection**: Automatically detects concerning symptoms (chest pain, suicidal ideation, etc.)
4. **Time Savings**: Providers review AI summaries instead of raw forms

### Who Uses It
- **Healthcare Providers** (doctors, nurses): Use the iOS app to manage patients and review intakes
- **Patients**: Receive a link and fill out forms on web (no app needed)

---

## For Web Developers: The Translation Guide

Coming from React/full-stack web dev? Here's how mobile concepts map to what you know.

### The Mental Model Shift

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WEB (React)          →      MOBILE (SwiftUI)         │
├─────────────────────────────────────────────────────────────────────────┤
│  Component                              →      View                     │
│  useState/useReducer                    →      @State / @Published      │
│  useContext                             →      @EnvironmentObject       │
│  useEffect                              →      .onAppear / .task        │
│  React Router                           →      NavigationStack          │
│  Tailwind CSS                           →      DesignSystem.swift       │
│  axios/fetch                            →      NetworkClient (URLSession)│
│  localStorage                           →      UserDefaults             │
│  IndexedDB                              →      SwiftData (Core Data)    │
│  npm/yarn                               →      Swift Package Manager    │
│  package.json                           →      Xcode project file       │
│  .env                                   →      Info.plist + Build Config│
│  Jest                                   →      XCTest                   │
│  console.log                            →      print()                  │
│  CSS Modules                            →      ViewModifiers            │
│  Redux/Zustand                          →      @Observable / Combine    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Code Comparison Examples

**React Component → SwiftUI View**
```jsx
// React
function PatientCard({ patient }) {
  const [isLoading, setIsLoading] = useState(false);

  return (
    <div className="card">
      <h2>{patient.name}</h2>
      <p>{patient.email}</p>
    </div>
  );
}
```

```swift
// SwiftUI
struct PatientCard: View {
    let patient: Patient
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text(patient.name)
                .font(.headline)
            Text(patient.email)
                .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}
```

**React Context → SwiftUI EnvironmentObject**
```jsx
// React
const AuthContext = createContext();

function App() {
  return (
    <AuthContext.Provider value={authState}>
      <Home />
    </AuthContext.Provider>
  );
}

function Home() {
  const auth = useContext(AuthContext);
}
```

```swift
// SwiftUI
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
}

struct IntakeAIApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

struct Home: View {
    @EnvironmentObject var auth: AuthViewModel
}
```

**fetch/axios → NetworkClient**
```javascript
// JavaScript
const response = await fetch('/api/patients', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const data = await response.json();
```

```swift
// Swift
let data = try await NetworkClient.shared.request(
    endpoint: "/patients",
    method: .get
)
let patients = try JSONDecoder().decode([Patient].self, from: data)
```

### Key Differences to Understand

| Web | Mobile | Why It's Different |
|-----|--------|-------------------|
| CSS is separate | Styles are inline modifiers | SwiftUI uses modifier chains |
| Async in effects | Async with `Task` and `.task` | Swift has built-in async/await |
| Virtual DOM diffing | Declarative UI with state | SwiftUI automatically updates views |
| Hot module reload | Xcode Preview | Similar but requires simulator/device |
| npm packages | Swift Packages + CocoaPods | Different package ecosystems |
| Browser DevTools | Xcode Debugger + Instruments | Different debugging tools |
| Responsive with CSS | GeometryReader + size classes | Different responsive approach |
| REST over HTTP | Same, but URLSession | Same concepts, different APIs |

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTAKEAI SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │                        iOS APP (SwiftUI)                        │     │
│    │                                                                  │     │
│    │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐ │     │
│    │  │ Dashboard  │  │  Patients  │  │  Intakes   │  │ Settings  │ │     │
│    │  └────────────┘  └────────────┘  └────────────┘  └───────────┘ │     │
│    │                                                                  │     │
│    │  ┌─────────────────────────────────────────────────────────────┐│     │
│    │  │                      Core Layer                             ││     │
│    │  │  NetworkClient │ DataStore │ DesignSystem │ Models          ││     │
│    │  └─────────────────────────────────────────────────────────────┘│     │
│    └──────────────────────────────┬──────────────────────────────────┘     │
│                                   │ HTTPS                                   │
│                                   ▼                                         │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │                    BACKEND API (Node.js)                        │     │
│    │                                                                  │     │
│    │  ┌──────────────────────────────────────────────────────────┐  │     │
│    │  │                      Routes                               │  │     │
│    │  │  /auth │ /patients │ /intake-links │ /intakes │ /summaries│  │     │
│    │  └──────────────────────────────────────────────────────────┘  │     │
│    │                                                                  │     │
│    │  ┌──────────────────────────────────────────────────────────┐  │     │
│    │  │                    Controllers                            │  │     │
│    │  │  authController │ patientController │ summaryController   │  │     │
│    │  └──────────────────────────────────────────────────────────┘  │     │
│    │                                                                  │     │
│    │  ┌──────────────────────────────────────────────────────────┐  │     │
│    │  │                     Services                              │  │     │
│    │  │              geminiService (AI summaries)                 │  │     │
│    │  └──────────────────────────────────────────────────────────┘  │     │
│    └──────────────────────────────┬──────────────────────────────────┘     │
│                                   │                                         │
│              ┌────────────────────┴────────────────────┐                   │
│              ▼                                         ▼                   │
│    ┌──────────────────┐                    ┌──────────────────────┐        │
│    │   PostgreSQL     │                    │    Google Gemini     │        │
│    │   (via Prisma)   │                    │    (AI Summaries)    │        │
│    └──────────────────┘                    └──────────────────────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. AUTHENTICATION
   User → iOS App → POST /api/auth/login → Backend → JWT tokens → iOS Keychain

2. PATIENT MANAGEMENT
   Provider → iOS App → GET /api/patients → Backend → Prisma → PostgreSQL
                                                            ↓
   Provider ← iOS App ← JSON Response ← Backend ← Patient data

3. INTAKE WORKFLOW
   Provider creates link → POST /api/intake-links → Link generated
   Patient opens link → GET /api/intake-links/:token → Form displayed
   Patient submits → POST /api/intake-links/:token/submit → Red flags detected
   Provider reviews → GET /api/intakes/:id → Intake data shown
   Provider requests AI → POST /api/summaries/generate → Gemini API → Summary

4. AI SUMMARY GENERATION
   iOS App → POST /api/summaries/generate/stream → Backend → Gemini API
                                                          ↓
   iOS App ← Server-Sent Events (streaming) ← Generated text chunks
```

---

## Directory Structure

```
mobile-intake-ai/
│
├── IntakeAI/                          # iOS App (Xcode Project)
│   ├── IntakeAI/
│   │   ├── IntakeAIApp.swift          # App entry point (like index.js)
│   │   │
│   │   ├── Core/                      # Shared infrastructure
│   │   │   ├── DesignSystem/          # UI components & theming
│   │   │   │   ├── DesignSystem.swift     # Colors, typography, spacing
│   │   │   │   ├── Components/            # Reusable UI components
│   │   │   │   │   ├── IAButton.swift     # Custom buttons
│   │   │   │   │   ├── IACard.swift       # Card containers
│   │   │   │   │   ├── IATextField.swift  # Form inputs
│   │   │   │   │   ├── IAModal.swift      # Modal dialogs
│   │   │   │   │   ├── IABadge.swift      # Status badges
│   │   │   │   │   ├── IAEmptyState.swift # Empty state views
│   │   │   │   │   └── IASkeletonViews.swift # Loading skeletons
│   │   │   │   └── Animations/
│   │   │   │       └── IAAnimations.swift # Animation definitions
│   │   │   │
│   │   │   ├── Network/               # API communication
│   │   │   │   ├── NetworkClient.swift    # HTTP client (like axios)
│   │   │   │   └── NetworkMonitor.swift   # Connection status
│   │   │   │
│   │   │   ├── Persistence/           # Local data storage
│   │   │   │   └── DataStore.swift        # SwiftData (like IndexedDB)
│   │   │   │
│   │   │   ├── Domain/Models/         # Data models (like TypeScript types)
│   │   │   │   ├── User.swift
│   │   │   │   ├── Patient.swift
│   │   │   │   ├── Intake.swift
│   │   │   │   ├── IntakeLink.swift
│   │   │   │   ├── Summary.swift
│   │   │   │   ├── Dashboard.swift
│   │   │   │   └── AuditLog.swift
│   │   │   │
│   │   │   └── Services/
│   │   │       └── CrashReporting.swift   # Sentry integration
│   │   │
│   │   ├── Features/                  # Feature modules (like pages/)
│   │   │   ├── Authentication/
│   │   │   │   ├── ViewModels/
│   │   │   │   │   └── AuthViewModel.swift    # Auth state & logic
│   │   │   │   └── Views/
│   │   │   │       ├── AuthenticationFlow.swift  # Login/Register
│   │   │   │       └── SplashScreen.swift
│   │   │   │
│   │   │   ├── Dashboard/
│   │   │   │   ├── ViewModels/
│   │   │   │   │   └── DashboardViewModel.swift
│   │   │   │   └── Views/
│   │   │   │       ├── DashboardView.swift
│   │   │   │       └── PatientKanbanView.swift
│   │   │   │
│   │   │   ├── Patients/
│   │   │   │   ├── ViewModels/
│   │   │   │   │   └── PatientsViewModel.swift
│   │   │   │   └── Views/
│   │   │   │       ├── PatientsListView.swift
│   │   │   │       └── PatientDetailView.swift
│   │   │   │
│   │   │   ├── Summary/
│   │   │   │   └── Views/
│   │   │   │       ├── SummaryDetailView.swift
│   │   │   │       └── AISummaryGenerationView.swift
│   │   │   │
│   │   │   ├── Onboarding/
│   │   │   │   └── Views/
│   │   │   │       └── OnboardingView.swift
│   │   │   │
│   │   │   ├── Settings/
│   │   │   │   └── Views/
│   │   │   │       └── SettingsView.swift
│   │   │   │
│   │   │   └── Main/
│   │   │       ├── MainTabView.swift      # iPhone tab navigation
│   │   │       └── iPadMainView.swift     # iPad split view
│   │   │
│   │   ├── Assets.xcassets/           # Images, colors, icons
│   │   │   ├── AppIcon.appiconset/    # App icons (all sizes)
│   │   │   └── Colors/                # Named color assets
│   │   │
│   │   └── Info.plist                 # App configuration (like .env)
│   │
│   └── GenerateAppIcon.swift          # Helper to generate icons
│
├── backend/                           # Node.js API Server
│   ├── src/
│   │   ├── index.js                   # Server entry point
│   │   │
│   │   ├── config/
│   │   │   └── index.js               # Environment config
│   │   │
│   │   ├── routes/                    # API routes (like Next.js API routes)
│   │   │   ├── auth.js                # /api/auth/*
│   │   │   ├── patients.js            # /api/patients/*
│   │   │   ├── intakes.js             # /api/intakes/* & /api/intake-links/*
│   │   │   └── summaries.js           # /api/summaries/*
│   │   │
│   │   ├── controllers/               # Route handlers
│   │   │   ├── authController.js      # register, login, refresh, logout
│   │   │   ├── patientController.js   # CRUD + dashboard stats
│   │   │   ├── intakeController.js    # Links, submissions, red flags
│   │   │   └── summaryController.js   # AI generation (sync & stream)
│   │   │
│   │   ├── middleware/
│   │   │   ├── auth.js                # JWT verification
│   │   │   ├── errorHandler.js        # Global error handling
│   │   │   └── validate.js            # Input validation
│   │   │
│   │   ├── services/
│   │   │   └── geminiService.js       # Google Gemini AI integration
│   │   │
│   │   └── utils/
│   │       ├── errors.js              # Custom error classes
│   │       └── logger.js              # Winston logging
│   │
│   ├── prisma/
│   │   └── schema.prisma              # Database schema (like SQL migrations)
│   │
│   ├── tests/                         # Jest tests
│   │   ├── auth.test.js
│   │   ├── patients.test.js
│   │   └── intakes.test.js
│   │
│   ├── package.json                   # Dependencies & scripts
│   ├── .env.example                   # Environment template
│   └── README.md                      # Backend-specific docs
│
├── business.md                        # Business strategy guide
├── pre-production.md                  # Production readiness audit
├── userExperience.md                  # UX/UI audit & education
├── trinity.md                         # Business + Tech + UX integration
└── README.md                          # This file
```

---

## Getting Started

### Prerequisites

**For iOS Development:**
- macOS (required for iOS development)
- Xcode 15+ (free from Mac App Store)
- iOS 16.0+ device or simulator
- Apple Developer account (free for testing, $99/year for App Store)

**For Backend:**
- Node.js 18+
- PostgreSQL 14+
- npm or yarn

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd mobile-intake-ai
```

### Step 2: Setup Backend

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your values:
# - DATABASE_URL: Your PostgreSQL connection string
# - JWT_ACCESS_SECRET: Generate with `openssl rand -base64 64`
# - JWT_REFRESH_SECRET: Generate with `openssl rand -base64 64`
# - GEMINI_API_KEY: Get from Google AI Studio

# Setup database
npm run db:generate    # Generate Prisma client
npm run db:push        # Push schema to database

# Start development server
npm run dev
```

The backend will run at `http://localhost:3001`.

### Step 3: Setup iOS App

```bash
# Navigate to iOS project
cd ../IntakeAI

# Open in Xcode
open IntakeAI.xcodeproj
```

In Xcode:
1. Select your development team in **Signing & Capabilities**
2. Select a simulator or connected device
3. Press **Cmd + R** to build and run

### Step 4: Configure API URL

By default, the iOS app connects to `http://localhost:3001/api` in debug mode.

To change this, edit `NetworkClient.swift`:
```swift
#if DEBUG
private let baseURL = "http://localhost:3001/api"  // Development
#else
private let baseURL = "https://api.yourapp.com/api"  // Production
#endif
```

### Step 5: Test the Flow

1. **Register** a new provider account in the iOS app
2. **Add a patient** with name, email, and date of birth
3. **Create an intake link** for the patient
4. **Open the link** in a browser to see the patient form
5. **Submit the form** and check for red flag detection
6. **Generate an AI summary** from the intake data

---

## Key Files Reference

### iOS App - Must-Know Files

| File | Purpose | Web Equivalent |
|------|---------|---------------|
| `IntakeAIApp.swift` | App entry point, environment setup | `index.js` + `App.js` |
| `NetworkClient.swift` | HTTP client with auth handling | `axios` instance |
| `AuthViewModel.swift` | Auth state, login/logout logic | Auth context + hooks |
| `DesignSystem.swift` | Colors, typography, spacing tokens | CSS variables / Tailwind config |
| `IAButton.swift` | Primary button component | `Button` component |
| `IATextField.swift` | Form input with validation | `Input` component |
| `Patient.swift` | Patient data model | TypeScript interface |
| `MainTabView.swift` | Tab navigation (iPhone) | React Router layout |
| `DashboardView.swift` | Home screen with stats | Dashboard page |
| `PatientsListView.swift` | Patient list with search | Patients list page |

### Backend - Must-Know Files

| File | Purpose | Notes |
|------|---------|-------|
| `src/index.js` | Express server setup | Entry point |
| `src/routes/*.js` | API route definitions | Like Next.js API routes |
| `src/controllers/*.js` | Request handlers | Business logic |
| `src/middleware/auth.js` | JWT verification | Runs before protected routes |
| `src/services/geminiService.js` | AI integration | Calls Google Gemini |
| `prisma/schema.prisma` | Database schema | Defines all tables |
| `.env` | Environment variables | Never commit this file |

### Configuration Files

| File | Purpose |
|------|---------|
| `IntakeAI/Info.plist` | iOS app configuration (permissions, settings) |
| `backend/package.json` | Node.js dependencies and scripts |
| `backend/prisma/schema.prisma` | Database schema |
| `backend/.env` | Environment variables (secrets, API keys) |

---

## API Documentation

### Authentication

All protected endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | Create new account | No |
| POST | `/api/auth/login` | Authenticate user | No |
| POST | `/api/auth/refresh` | Refresh access token | Cookie |
| POST | `/api/auth/logout` | Clear session | Cookie |
| GET | `/api/auth/me` | Get current user | Yes |

### Patients

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/patients` | List patients (paginated, searchable) | Yes |
| GET | `/api/patients/:id` | Get patient with intakes | Yes |
| POST | `/api/patients` | Create patient | Yes |
| PUT | `/api/patients/:id` | Update patient | Yes |
| DELETE | `/api/patients/:id` | Delete patient | Yes |
| GET | `/api/patients/stats` | Dashboard statistics | Yes |

### Intake Links

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/intake-links` | Create intake link | Yes |
| GET | `/api/intake-links/:token` | Get link info (public) | No |
| POST | `/api/intake-links/:token/submit` | Submit intake (public) | No |

### Intakes

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/intakes` | List intakes | Yes |
| GET | `/api/intakes/:id` | Get intake details | Yes |
| POST | `/api/intakes/:id/review` | Mark as reviewed | Yes |

### Summaries

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/summaries` | List summaries | Yes |
| GET | `/api/summaries/:id` | Get summary | Yes |
| POST | `/api/summaries/generate` | Generate AI summary | Yes |
| POST | `/api/summaries/generate/stream` | Stream AI generation | Yes |
| DELETE | `/api/summaries/:id` | Delete summary | Yes |

### Response Format

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATABASE SCHEMA                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐     ┌──────────────────┐                               │
│  │    users    │     │  refresh_tokens  │                               │
│  ├─────────────┤     ├──────────────────┤                               │
│  │ id          │────<│ userId           │                               │
│  │ email       │     │ token            │                               │
│  │ passwordHash│     │ expiresAt        │                               │
│  │ firstName   │     └──────────────────┘                               │
│  │ lastName    │                                                        │
│  │ title       │                                                        │
│  │ practiceName│                                                        │
│  └──────┬──────┘                                                        │
│         │                                                               │
│         │ 1:many                                                        │
│         ▼                                                               │
│  ┌─────────────┐     ┌──────────────────┐                               │
│  │  patients   │     │   intake_links   │                               │
│  ├─────────────┤     ├──────────────────┤                               │
│  │ id          │────<│ patientId        │                               │
│  │ providerId  │     │ token (unique)   │                               │
│  │ firstName   │     │ status           │                               │
│  │ lastName    │     │ expiresAt        │                               │
│  │ email       │     └────────┬─────────┘                               │
│  │ dateOfBirth │              │ 1:1                                     │
│  └──────┬──────┘              ▼                                         │
│         │              ┌──────────────────┐                             │
│         │ 1:many       │     intakes      │                             │
│         └─────────────>├──────────────────┤                             │
│                        │ id               │                             │
│                        │ patientId        │                             │
│                        │ intakeLinkId     │                             │
│                        │ demographics     │  (JSON)                     │
│                        │ chiefComplaint   │                             │
│                        │ medicalHistory   │  (JSON)                     │
│                        │ medications      │  (JSON)                     │
│                        │ allergies        │  (JSON)                     │
│                        │ status           │                             │
│                        └────────┬─────────┘                             │
│                                 │                                       │
│              ┌──────────────────┼──────────────────┐                    │
│              │ 1:many           │ 1:many           │                    │
│              ▼                  ▼                  │                    │
│       ┌─────────────┐   ┌─────────────┐           │                    │
│       │  red_flags  │   │  summaries  │           │                    │
│       ├─────────────┤   ├─────────────┤           │                    │
│       │ id          │   │ id          │           │                    │
│       │ intakeId    │   │ intakeId    │           │                    │
│       │ category    │   │ content     │           │                    │
│       │ description │   │ model       │           │                    │
│       │ severity    │   │ tokensUsed  │           │                    │
│       └─────────────┘   └─────────────┘           │                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

Enums:
- LinkStatus: PENDING | COMPLETED | EXPIRED
- IntakeStatus: READY_FOR_REVIEW | REVIEWED
- FlagSeverity: LOW | MEDIUM | HIGH | CRITICAL
```

---

## Design System

The iOS app uses a comprehensive design system for consistent UI.

### Colors (Sage Green Healthcare Theme)

| Name | Usage | Light Mode | Dark Mode |
|------|-------|------------|-----------|
| Primary | Buttons, links | #4A7C59 | #6B9B7A |
| Background | Screen backgrounds | System | System |
| Surface | Cards, containers | White | Dark Gray |
| Error | Validation, destructive | #DC2626 | #EF4444 |
| Warning | Alerts | Orange | Orange |
| Success | Confirmations | Green | Green |

### Typography

```swift
DesignSystem.Typography.displayLarge   // Page titles
DesignSystem.Typography.headlineMedium // Section headers
DesignSystem.Typography.bodyLarge      // Body text
DesignSystem.Typography.labelSmall     // Captions
```

### Spacing (8pt Grid)

```swift
DesignSystem.Spacing.xs   // 8pt
DesignSystem.Spacing.sm   // 12pt
DesignSystem.Spacing.md   // 16pt
DesignSystem.Spacing.lg   // 20pt
DesignSystem.Spacing.xl   // 24pt
```

### Components

| Component | Description | Usage |
|-----------|-------------|-------|
| `IAButton` | Primary button with variants | Actions, CTAs |
| `IACard` | Container with shadow | Content grouping |
| `IATextField` | Form input with validation | Forms |
| `IABadge` | Status indicator | Status display |
| `IAModal` | Dialog overlay | Confirmations |
| `IAEmptyState` | Empty list placeholder | No data states |
| `IASkeletonViews` | Loading placeholders | Loading states |

---

## For LLMs: Context & Instructions

> This section provides context for AI assistants working on this codebase.

### Project Overview

IntakeAI is a healthcare patient intake management system consisting of:
1. **Native iOS app** built with SwiftUI (iOS 16+)
2. **Node.js/Express backend** with PostgreSQL via Prisma
3. **Google Gemini AI** for clinical summary generation

### Architecture Pattern

**iOS App:** MVVM (Model-View-ViewModel)
- Views: SwiftUI views (presentation)
- ViewModels: `@Observable` classes (business logic)
- Models: Codable structs (data)
- Services: Singleton actors (networking, persistence)

**Backend:** MVC-ish
- Routes → Controllers → Services → Prisma → PostgreSQL
- JWT authentication with HttpOnly cookies
- Express middleware for auth, validation, errors

### Key Technical Decisions

1. **Native iOS vs React Native**: Chose native for performance and Apple HIG compliance
2. **SwiftUI vs UIKit**: SwiftUI for modern declarative UI
3. **Prisma vs raw SQL**: Prisma for type safety and migrations
4. **Gemini vs GPT**: Gemini for healthcare-appropriate responses and pricing

### Important Patterns

**Networking (iOS):**
```swift
// NetworkClient is an actor (thread-safe singleton)
let data = try await NetworkClient.shared.request(endpoint: "/patients")
```

**State Management (iOS):**
```swift
// ViewModels use @Published for reactive updates
@MainActor
class PatientsViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
}
```

**Error Handling (Backend):**
```javascript
// Custom errors with proper HTTP status codes
throw new AuthenticationError('Invalid credentials');
throw new NotFoundError('Patient');
throw new ValidationError('Invalid email format');
```

### Code Style Guidelines

**Swift:**
- Use `@MainActor` for ViewModels
- Prefer `actor` for shared resources
- Use `async/await` for async operations
- Follow Apple naming conventions

**JavaScript:**
- Use `async/await` over callbacks
- Use Prisma for all database operations
- Validate all inputs with express-validator
- Use custom error classes

### Files to Read First

1. `IntakeAI/IntakeAIApp.swift` - App structure and environment
2. `IntakeAI/Core/Network/NetworkClient.swift` - How API calls work
3. `backend/src/index.js` - Server setup
4. `backend/prisma/schema.prisma` - Data model
5. `backend/src/controllers/authController.js` - Auth flow

### Common Tasks

**Adding a new API endpoint:**
1. Add route in `backend/src/routes/`
2. Add controller in `backend/src/controllers/`
3. Add corresponding method in `NetworkClient.swift`
4. Add model in `IntakeAI/Core/Domain/Models/`

**Adding a new screen:**
1. Create View in `Features/[Feature]/Views/`
2. Create ViewModel in `Features/[Feature]/ViewModels/`
3. Add navigation in appropriate parent view

**Adding a new component:**
1. Create in `Core/DesignSystem/Components/`
2. Follow `IA` naming prefix convention
3. Support light/dark mode via DesignSystem.Colors

---

## Documentation

This project includes comprehensive documentation:

| Document | Description |
|----------|-------------|
| [pre-production.md](./pre-production.md) | Production readiness audit, security issues, deployment checklist |
| [business.md](./business.md) | Business model, pricing strategy, go-to-market plan |
| [userExperience.md](./userExperience.md) | UX/UI audit, user journey mapping, design recommendations |
| [trinity.md](./trinity.md) | How business, technology, and UX interconnect |
| [backend/README.md](./backend/README.md) | Backend-specific documentation |

---

## Tech Stack

### iOS App

| Technology | Purpose |
|------------|---------|
| Swift 5.9 | Programming language |
| SwiftUI | UI framework |
| SwiftData | Local persistence (offline support) |
| Combine | Reactive programming |
| URLSession | Networking |
| Keychain | Secure token storage |
| LocalAuthentication | Face ID / Touch ID |

### Backend

| Technology | Purpose |
|------------|---------|
| Node.js 18+ | Runtime |
| Express 4.x | Web framework |
| Prisma 5.x | ORM |
| PostgreSQL 14+ | Database |
| JWT | Authentication |
| bcryptjs | Password hashing |
| Winston | Logging |
| Jest | Testing |

### External Services

| Service | Purpose |
|---------|---------|
| Google Gemini | AI summary generation |
| Sentry | Error tracking (optional) |

---

## Scripts Reference

### Backend (`npm run ...`)

| Script | Description |
|--------|-------------|
| `dev` | Start with nodemon (hot reload) |
| `start` | Start production server |
| `db:generate` | Generate Prisma client |
| `db:push` | Push schema to database |
| `db:migrate` | Run migrations |
| `db:studio` | Open Prisma Studio (database GUI) |
| `test` | Run tests with coverage |
| `test:watch` | Run tests in watch mode |

### iOS (Xcode)

| Action | Shortcut |
|--------|----------|
| Build | Cmd + B |
| Run | Cmd + R |
| Test | Cmd + U |
| Clean | Cmd + Shift + K |
| Preview | Cmd + Option + P |

---

## License

[Add your license here]

---

## Contributing

[Add contribution guidelines here]

---

**Built with ❤️ for healthcare providers who deserve better tools.**

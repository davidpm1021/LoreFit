# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LoreFit is a fitness-gated collaborative storytelling web application where users earn the right to contribute to shared stories through fitness achievements. Users connect fitness trackers (Strava, Fitbit) or manually log workouts to earn points, which they spend to add sentences to collaborative narratives.

**Current Status:** Planning phase - comprehensive design document completed in `projectplan.md`, no code implementation yet.

**Target Scale:** 5-20 initial users, designed to scale to 500+ without architecture changes.

## Technology Stack

- **Frontend:** Next.js 15 (App Router), React 18+, TypeScript, Tailwind CSS
- **Backend:** Supabase (PostgreSQL, real-time subscriptions, authentication, Edge functions)
- **State Management:** Zustand (UI state), React Query/TanStack Query (server state), Supabase Realtime (live updates)
- **Real-time Collaboration:** Yjs CRDT with WebSocket provider
- **Deployment:** Vercel
- **Security:** AES-256-GCM encryption, OAuth 2.0 with PKCE
- **Rate Limiting:** Upstash Redis
- **Monitoring:** Sentry, Vercel Analytics
- **Testing:** Vitest (unit/integration), Playwright (E2E)

## Development Commands

When implementing this project, use these commands:

```bash
# Development
npm run dev                 # Start Next.js development server
npm run build               # Production build
npm run start               # Start production server

# Code Quality
npm run lint                # Run ESLint
npm run type-check          # TypeScript validation
npm run format              # Format code with Prettier

# Testing
npm run test                # Run all tests
npm run test:unit           # Vitest unit tests
npm run test:integration    # Integration tests
npm run test:e2e            # Playwright E2E tests
npm run test:watch          # Watch mode for unit tests

# Database
npm run db:migrate          # Run database migrations
npm run db:reset            # Reset database
npm run db:seed             # Seed test data
```

## High-Level Architecture

### Three Core Systems

1. **Fitness Integration Layer**
   - OAuth 2.0 flows for Strava and Fitbit (with PKCE for Fitbit)
   - Data normalization layer converts different API formats to common schema
   - Background sync with webhook-triggered updates
   - Offline queue for manual entries
   - Token encryption (AES-256-GCM) in `activity_sync` table

2. **Gamification Engine**
   - Personalized baseline calculation from 4 weeks of historical data
   - Adaptive baselines using exponential moving average
   - Point rewards: base (10pts/workout) + intensity bonuses (5-20pts) + consistency rewards
   - Challenge system with weekly/monthly goals
   - Anti-gaming measures: point caps, personalized thresholds

3. **Collaborative Storytelling System**
   - Yjs CRDT for conflict-free concurrent editing
   - WebSocket-based real-time collaboration via Supabase
   - IndexedDB persistence for offline support
   - Cost-based contribution gating (10-75 points)
   - Voting system with weighted votes based on participation
   - Character limits: 10-280 characters per contribution

### Database Schema Key Points

**Core Tables:**
- `profiles` - User profiles with fitness level
- `user_points` - Points balance, history, level
- `workouts` - Normalized fitness activity data from all sources
- `activity_sync` - Encrypted OAuth tokens, sync status
- `stories` - Story metadata, genre, tone, status
- `story_contributions` - Individual contributions with voting
- `user_baselines` - Personalized fitness thresholds
- `user_challenges` - Active challenges and progress

**Security:** Row-Level Security (RLS) policies enforce data access controls. Users can only read their own fitness data. Stories are publicly readable but contributions are user-owned.

### State Management Strategy

- **Zustand:** Ephemeral UI state (modals, preferences, cursor positions)
- **React Query:** Server state caching, automatic invalidation, optimistic updates
- **Supabase Realtime:** WebSocket subscriptions for live collaboration
- **Yjs CRDT:** Conflict-free distributed editing state

### API Integration Patterns

**Strava:**
- OAuth 2.0 without PKCE
- Webhook support for automatic sync
- Token refresh before 1-hour expiry
- Activity types: Run, Ride, Swim, Hike, Walk, Workout

**Fitbit:**
- OAuth 2.0 with PKCE required
- 8-hour token expiry (aggressive refresh)
- Rate limit: 150 requests/hour per user
- Intraday data requires manual approval

**Normalization:**
All activities converted to common schema:
```typescript
{
  date, type, duration_minutes, distance_km?,
  calories?, heart_rate_avg?, intensity,
  raw_source: 'strava' | 'fitbit' | 'manual'
}
```

### Security Implementation

1. **Data Encryption:** All OAuth tokens encrypted with AES-256-GCM before storage
2. **Authentication:** Supabase Auth with OAuth providers, JWT sessions
3. **Rate Limiting:** Upstash Redis with sliding window algorithm
   - Auth endpoints: 5 attempts / 15 minutes
   - API endpoints: 100 requests / minute
   - Workout logging: 10 workouts / hour
4. **Audit Logging:** All sensitive operations logged with IP/user agent

### Real-time Collaboration Architecture

**Yjs CRDT Setup:**
- One Y.Doc per story
- WebSocket provider connects through Supabase
- IndexedDB for offline persistence
- Awareness API for cursor tracking
- Automatic conflict resolution

**Contribution Flow:**
1. User types in editor (local CRDT updates)
2. Check points balance
3. Submit contribution (deduct points, record in DB)
4. CRDT syncs to all connected clients
5. Voting period begins (30 minutes)

### Progressive Web App Features

- Service worker with cache-first strategy for static assets
- Network-first strategy for API calls and HTML
- Background sync for offline workout submissions
- Push notifications for story updates and challenges
- Manifest with shortcuts for quick actions

## Implementation Order

When building this application, follow this sequence:

1. **Foundation (Week 1)**
   - Initialize Next.js 15 project with TypeScript
   - Set up Supabase project
   - Configure Tailwind CSS
   - Create database schema and migrations
   - Implement authentication flows

2. **Fitness Layer (Week 2)**
   - Build manual workout entry form
   - Implement Strava OAuth and sync
   - Create data normalization layer
   - Add baseline calculation logic

3. **Gamification (Week 3)**
   - Implement point calculation system
   - Build user dashboard with points display
   - Create challenge assignment logic
   - Add weekly goal tracking

4. **Storytelling (Week 4)**
   - Set up Yjs CRDT infrastructure
   - Build story creation UI
   - Implement contribution editor
   - Add voting system

5. **Polish (Week 5)**
   - Add Fitbit integration
   - Implement PWA features
   - Set up monitoring (Sentry)
   - Add E2E tests

## Key Design Decisions

### Why Next.js App Router?
- Server components reduce client bundle size
- Built-in route handlers replace separate API
- Streaming and suspense for better UX
- Excellent TypeScript support

### Why Supabase over Custom Backend?
- PostgreSQL with full SQL access (no vendor lock-in)
- Built-in real-time subscriptions
- Row-Level Security reduces auth code
- Free tier sufficient for MVP
- Easy migration path to self-hosted

### Why Yjs CRDT?
- Proven offline-first collaboration
- Better than operational transforms for this use case
- IndexedDB persistence built-in
- WebSocket provider integrates with Supabase

### Point Economy Balance
Based on target of 100 points/week for moderate user:
- 3-4 workouts/week × 10 base points = 30-40 points
- Intensity bonuses add 10-20 points
- Weekly challenges add 25-40 points
- Story contribution costs: 10pts (sentence), 25pts (twist), 50pts (ending)

This creates tension: contribute frequently (cheap) vs. save for high-impact moments.

## Testing Strategy

- **Unit Tests (Vitest):** All utilities, point calculations, normalization functions
- **Integration Tests:** API routes with mocked Supabase
- **E2E Tests (Playwright):** Critical user journeys
  - Sign up → Connect Strava → Log workout → Earn points
  - Join story → Add contribution → Vote on others
  - Complete challenge → Earn bonus points

**Coverage Target:** >70% overall, 100% for gamification logic

## Environment Variables Required

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY

# Fitness APIs
STRAVA_CLIENT_ID
STRAVA_CLIENT_SECRET
FITBIT_CLIENT_ID
FITBIT_CLIENT_SECRET

# Security
ENCRYPTION_KEY                 # 64-character hex string for AES-256
JWT_SECRET
NEXTAUTH_SECRET

# App
NEXT_PUBLIC_APP_URL
NEXT_PUBLIC_WEBSOCKET_URL

# Monitoring
SENTRY_DSN
NEXT_PUBLIC_VERCEL_ANALYTICS_ID

# Rate Limiting
UPSTASH_REDIS_URL
UPSTASH_REDIS_TOKEN
```

## Important Constraints and Anti-Patterns

### Point System Anti-Gaming
- Maximum 50 points per workout (prevents duration inflation)
- Duplicate detection by date/type/duration (prevents double-logging)
- Cooldown periods between contributions (prevents spam)
- Baselines adjust over time (prevents sandbagging)

### Security Considerations
- Never log decrypted tokens
- Always validate points balance before deduction
- Use RLS policies, don't trust client permissions
- Rate limit all user-facing endpoints
- Audit all point transactions

### Performance Patterns
- Use React Query for server state (not useState + useEffect)
- Implement optimistic updates for better UX
- Cache fitness data, sync in background
- Use materialized views for leaderboards
- Index all foreign keys and query predicates

## Critical File Locations (Once Implemented)

- Point calculation: `lib/gamification/points.ts`
- Baseline logic: `lib/gamification/baseline.ts`
- Strava integration: `lib/fitness/strava/`
- CRDT collaboration: `lib/stories/collaboration.ts`
- Token encryption: `lib/security/encryption.ts`
- Database migrations: `migrations/`
- API routes: `app/api/`
- Main dashboard: `app/(auth)/dashboard/page.tsx`

## Reference Documentation

The complete technical specification is in `projectplan.md` (2,166 lines). It contains:
- Detailed database schema with SQL
- Complete API integration code examples
- Security implementation details
- Deployment configuration
- Scaling considerations
- Launch checklist

Refer to this document for implementation details when building features.

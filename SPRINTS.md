# LoreFit Sprint Plan: Foundation to MVP

This document outlines a structured sprint plan to build LoreFit from the ground up, following software engineering best practices. Each sprint is 1 week (5 working days) with clear deliverables and acceptance criteria.

---

## Sprint 0: Project Setup & Infrastructure (Week 1)

**Goal:** Establish development environment, tooling, and foundational infrastructure.

### Tasks

**Day 1-2: Project Initialization**
- [ ] Initialize Next.js 15 project with TypeScript
  ```bash
  npx create-next-app@latest lorefit --typescript --tailwind --app --eslint
  ```
- [ ] Configure package.json with all required dependencies
- [ ] Set up Git repository with proper .gitignore
- [ ] Create development, staging, production branch strategy
- [ ] Configure ESLint with security and TypeScript rules
- [ ] Set up Prettier with Tailwind plugin
- [ ] Configure Husky for pre-commit hooks (lint, type-check)
- [ ] Create `.env.example` with all required variables

**Day 3: Supabase Setup**
- [ ] Create Supabase project
- [ ] Initialize Supabase client in `lib/supabase/client.ts` and `lib/supabase/server.ts`
- [ ] Set up environment variables for Supabase
- [ ] Configure Row-Level Security (RLS) policies
- [ ] Create initial database migration structure
- [ ] Test connection from Next.js app

**Day 4: Testing Infrastructure**
- [ ] Install and configure Vitest
- [ ] Set up React Testing Library
- [ ] Create `test/setup.ts` with global test configuration
- [ ] Install and configure Playwright
- [ ] Create first smoke test (app loads)
- [ ] Configure test scripts in package.json
- [ ] Set up test coverage reporting

**Day 5: CI/CD Pipeline**
- [ ] Create `.github/workflows/ci.yml`
- [ ] Configure GitHub Actions for:
  - Lint and type-check on every PR
  - Run tests on every PR
  - Security audit (npm audit)
- [ ] Set up Vercel project
- [ ] Configure automatic preview deployments
- [ ] Test full CI/CD pipeline with dummy PR

### Deliverables
- ✅ Fully configured Next.js 15 + TypeScript + Tailwind project
- ✅ Supabase project connected and tested
- ✅ Working test suite (unit + E2E)
- ✅ CI/CD pipeline running on GitHub + Vercel
- ✅ Development environment documented in README.md

### Acceptance Criteria
- `npm run dev` starts development server
- `npm run test` passes all tests
- `npm run lint` passes with no errors
- GitHub Actions workflow passes
- Vercel preview deployment works

---

## Sprint 1: Database Schema & Authentication (Week 2)

**Goal:** Implement complete database schema with migrations and basic authentication.

### Tasks

**Day 1-2: Database Schema**
- [ ] Create migration for `profiles` table
- [ ] Create migration for `user_points` table
- [ ] Create migration for `workouts` table with indexes
- [ ] Create migration for `activity_sync` table
- [ ] Create migration for `user_baselines` table
- [ ] Create migration for `user_challenges` table
- [ ] Add all necessary indexes for performance
- [ ] Write SQL for RLS policies on each table
- [ ] Test migrations: `npm run db:migrate`
- [ ] Create database seed script with sample data

**Day 3: TypeScript Types**
- [ ] Create `types/database.ts` with all table types
- [ ] Generate types from Supabase: `supabase gen types typescript`
- [ ] Create `types/fitness.ts` for workout data
- [ ] Create `types/gamification.ts` for points and challenges
- [ ] Create shared utility types

**Day 4-5: Authentication**
- [ ] Implement Supabase Auth helpers for Next.js App Router
- [ ] Create authentication context/hooks
- [ ] Build sign-up page with email/password
- [ ] Build login page
- [ ] Implement password reset flow
- [ ] Create profile setup page (username, fitness level)
- [ ] Add middleware for protected routes
- [ ] Create auth utilities for server components
- [ ] Write tests for auth flows

### Deliverables
- ✅ Complete database schema deployed to Supabase
- ✅ RLS policies active and tested
- ✅ TypeScript types for all database entities
- ✅ Working authentication system
- ✅ Protected route middleware

### Acceptance Criteria
- Users can sign up with email/password
- Users can log in and log out
- Protected routes redirect unauthenticated users
- Profile is created automatically on signup
- User points record initialized to 0
- All RLS policies tested and working
- Test coverage >70% for auth code

---

## Sprint 2: Core UI Components & Design System (Week 3)

**Goal:** Build reusable UI component library and main application layout.

### Tasks

**Day 1-2: Base UI Components**
- [ ] Create `components/ui/button.tsx` with variants
- [ ] Create `components/ui/input.tsx` with validation states
- [ ] Create `components/ui/card.tsx`
- [ ] Create `components/ui/badge.tsx`
- [ ] Create `components/ui/modal.tsx`
- [ ] Create `components/ui/toast.tsx` for notifications
- [ ] Create `components/ui/progress.tsx`
- [ ] Create `components/ui/tabs.tsx`
- [ ] Write Storybook stories or unit tests for each component
- [ ] Document component props and usage

**Day 3: Layout Components**
- [ ] Create `app/layout.tsx` with global styles
- [ ] Create `components/layout/header.tsx` with navigation
- [ ] Create `components/layout/sidebar.tsx` for dashboard
- [ ] Create `components/layout/mobile-nav.tsx`
- [ ] Implement responsive behavior (mobile-first)
- [ ] Add user avatar/menu in header
- [ ] Create loading states skeleton components

**Day 4: Dashboard Components**
- [ ] Create `components/dashboard/points-card.tsx`
- [ ] Create `components/dashboard/weekly-activity-chart.tsx`
- [ ] Create `components/dashboard/challenge-card.tsx`
- [ ] Create `components/dashboard/mini-leaderboard.tsx`
- [ ] Create `components/dashboard/quick-actions.tsx`
- [ ] Use mock data for all components

**Day 5: Testing & Polish**
- [ ] Write component tests with React Testing Library
- [ ] Test responsive behavior at mobile/tablet/desktop
- [ ] Add accessibility attributes (ARIA labels)
- [ ] Test keyboard navigation
- [ ] Create global Tailwind theme configuration
- [ ] Document design system patterns

### Deliverables
- ✅ Complete UI component library
- ✅ Responsive layout system
- ✅ Dashboard component suite
- ✅ Design system documentation

### Acceptance Criteria
- All components render without errors
- Components are responsive (320px - 1920px)
- Components have proper TypeScript types
- Test coverage >80% for UI components
- Accessibility score >90 (Lighthouse)
- Components work in light/dark mode (bonus)

---

## Sprint 3: Manual Workout Logging & Points System (Week 4)

**Goal:** Implement core gamification loop - log workouts, earn points.

### Tasks

**Day 1: Workout Entry Form**
- [ ] Create `app/(auth)/workouts/new/page.tsx`
- [ ] Build `components/workout/manual-entry-form.tsx`
- [ ] Add workout type selector (running, cycling, swimming, etc.)
- [ ] Add duration input with validation (min 5 minutes)
- [ ] Add optional distance input
- [ ] Add date picker (default: today)
- [ ] Add notes field
- [ ] Implement form validation with Zod
- [ ] Add loading states during submission

**Day 2: Workout API & Database**
- [ ] Create `app/api/workouts/route.ts` (POST endpoint)
- [ ] Implement duplicate detection logic
- [ ] Add workout to database
- [ ] Create `lib/fitness/normalizer.ts` for manual entries
- [ ] Write tests for API endpoint
- [ ] Add error handling and validation
- [ ] Create `app/api/workouts/[id]/route.ts` (GET, DELETE)

**Day 3: Points Calculation System**
- [ ] Create `lib/gamification/points.ts` with POINT_VALUES constants
- [ ] Implement `calculateWorkoutPoints()` function
- [ ] Create `lib/gamification/baseline.ts`
- [ ] Implement `calculateUserBaseline()` function
- [ ] Implement baseline initialization (4 weeks of data)
- [ ] Create database function for point transactions
- [ ] Implement atomic point updates (prevent race conditions)
- [ ] Write comprehensive tests for point calculations

**Day 4: Points Integration**
- [ ] Update workout POST endpoint to calculate and award points
- [ ] Create `app/api/points/route.ts` (GET user points)
- [ ] Create `app/api/points/history/route.ts`
- [ ] Implement points history JSONB updates
- [ ] Create React Query hooks: `useUserPoints()`, `useWorkouts()`
- [ ] Update dashboard to show real points
- [ ] Add point transaction notifications (toast)

**Day 5: Workout History & Testing**
- [ ] Create `app/(auth)/workouts/page.tsx` (workout list)
- [ ] Create `components/workout/workout-list.tsx`
- [ ] Create `components/workout/workout-card.tsx`
- [ ] Add filters (date range, type)
- [ ] Add delete workout functionality
- [ ] Write E2E test: complete user journey (signup → workout → points)
- [ ] Test edge cases (duplicate workouts, point caps)
- [ ] Performance test: 100 workouts rendering

### Deliverables
- ✅ Working manual workout entry system
- ✅ Points calculation engine
- ✅ Baseline tracking system
- ✅ Workout history view
- ✅ Complete gamification loop

### Acceptance Criteria
- Users can log workouts via form
- Points are calculated and awarded correctly
- Baselines are calculated from historical data
- Workout history displays all user workouts
- Points balance updates in real-time
- No duplicate workouts allowed
- Test coverage >80% for gamification logic
- E2E test passes for full user journey

---

## Sprint 4: Strava Integration (Week 5)

**Goal:** Connect Strava, sync activities, automate point awards.

### Tasks

**Day 1: OAuth Setup**
- [ ] Register app with Strava API
- [ ] Create `lib/fitness/strava/auth.ts`
- [ ] Implement `initiateStravaAuth()` function
- [ ] Create `app/api/auth/strava/callback/route.ts`
- [ ] Implement OAuth token exchange
- [ ] Test OAuth flow end-to-end
- [ ] Add error handling for OAuth failures

**Day 2: Token Management & Encryption**
- [ ] Create `lib/security/encryption.ts`
- [ ] Implement AES-256-GCM encryption functions
- [ ] Generate ENCRYPTION_KEY and add to env
- [ ] Create `storeEncryptedTokens()` function
- [ ] Create `getDecryptedTokens()` function
- [ ] Implement token refresh logic
- [ ] Test encryption/decryption with actual tokens
- [ ] Write security tests

**Day 3: Activity Sync**
- [ ] Create `lib/fitness/strava/sync.ts`
- [ ] Implement `syncStravaActivities()` function
- [ ] Implement activity normalization for Strava
- [ ] Create background sync job/cron
- [ ] Handle pagination for large activity lists
- [ ] Implement incremental sync (only new activities)
- [ ] Add sync status tracking in `activity_sync` table
- [ ] Test with real Strava account

**Day 4: UI Integration**
- [ ] Create `components/fitness/connect-strava-button.tsx`
- [ ] Add Strava connection card to dashboard
- [ ] Show sync status and last sync time
- [ ] Add manual sync button
- [ ] Display Strava workouts in workout history (with icon)
- [ ] Create disconnect flow
- [ ] Add loading states during sync

**Day 5: Webhooks & Testing**
- [ ] Create `app/api/webhooks/strava/route.ts`
- [ ] Implement Strava webhook subscription
- [ ] Handle webhook events (new activity, deleted activity)
- [ ] Verify webhook signatures
- [ ] Test webhook with ngrok/local tunnel
- [ ] Write integration tests for sync
- [ ] Test error cases (invalid tokens, API down)
- [ ] Performance test: sync 100 activities

### Deliverables
- ✅ Complete Strava OAuth integration
- ✅ Encrypted token storage
- ✅ Automatic activity sync
- ✅ Webhook-triggered updates
- ✅ Strava connection UI

### Acceptance Criteria
- Users can connect Strava account
- OAuth flow completes successfully
- Tokens are encrypted in database
- Activities sync automatically
- Points awarded for Strava workouts
- Webhooks trigger immediate sync
- Token refresh works automatically
- No plaintext tokens in logs or database
- Test coverage >70% for Strava code

---

## Sprint 5: Story Schema & Database (Week 6)

**Goal:** Implement database structure for collaborative storytelling.

### Tasks

**Day 1-2: Story Database Schema**
- [ ] Create migration for `stories` table
- [ ] Create migration for `story_contributions` table
- [ ] Create migration for `contribution_votes` table
- [ ] Add indexes for story queries
- [ ] Implement RLS policies for stories
- [ ] Create TypeScript types for story entities
- [ ] Write seed script for sample stories

**Day 2-3: Story API Endpoints**
- [ ] Create `app/api/stories/route.ts` (GET all, POST new)
- [ ] Create `app/api/stories/[id]/route.ts` (GET, PATCH, DELETE)
- [ ] Create `app/api/stories/[id]/contributions/route.ts` (GET, POST)
- [ ] Implement story creation logic
- [ ] Implement contribution validation (10-280 chars)
- [ ] Add point deduction on contribution
- [ ] Write tests for all endpoints

**Day 4: Story Prompts & Generation**
- [ ] Create `lib/stories/prompts.ts`
- [ ] Implement genre-based prompts (fantasy, sci-fi, comedy, etc.)
- [ ] Implement tone modifiers (serious, comedic, dark, chaotic)
- [ ] Create `generateStoryPrompt()` function
- [ ] Create prompt library (20+ prompts per genre)
- [ ] Test prompt generation

**Day 5: Story Utilities**
- [ ] Create React Query hooks: `useStories()`, `useStory(id)`
- [ ] Create `lib/stories/utils.ts` for story helpers
- [ ] Implement story rendering (contributions → full text)
- [ ] Add contribution sorting and pagination
- [ ] Write tests for story utilities

### Deliverables
- ✅ Complete story database schema
- ✅ Story and contribution API endpoints
- ✅ Story prompt generation system
- ✅ Story utility functions and hooks

### Acceptance Criteria
- Stories can be created with genre/tone
- Contributions can be added to stories
- RLS policies protect story data
- Prompts generate appropriately for genre/tone
- Test coverage >70% for story code
- API validates contribution length
- Points are deducted on contribution

---

## Sprint 6: Story UI & Basic Collaboration (Week 7)

**Goal:** Build story browsing, reading, and contribution interfaces.

### Tasks

**Day 1: Story List & Discovery**
- [ ] Create `app/(auth)/stories/page.tsx`
- [ ] Create `components/story/story-card.tsx`
- [ ] Display active stories in grid
- [ ] Add genre/tone badges
- [ ] Show contribution count and participants
- [ ] Implement story filtering (genre, status)
- [ ] Add "Create Story" button
- [ ] Implement infinite scroll or pagination

**Day 2: Story Creation UI**
- [ ] Create `app/(auth)/stories/new/page.tsx`
- [ ] Create `components/story/story-creation-form.tsx`
- [ ] Add title input
- [ ] Add genre selector
- [ ] Add tone selector
- [ ] Add optional description
- [ ] Show generated prompt preview
- [ ] Implement form submission
- [ ] Redirect to story page after creation

**Day 3: Story Reading View**
- [ ] Create `app/(auth)/stories/[id]/page.tsx`
- [ ] Create `components/story/story-reader.tsx`
- [ ] Display full story text (all contributions)
- [ ] Highlight individual contributions
- [ ] Show contributor avatars/names
- [ ] Add timestamps for contributions
- [ ] Format text for readability
- [ ] Add story metadata sidebar

**Day 4: Contribution Editor**
- [ ] Create `components/story/contribution-editor.tsx`
- [ ] Add textarea with character counter
- [ ] Show points cost (10-75 based on type)
- [ ] Disable if insufficient points
- [ ] Add contribution type selector (sentence, twist, character, ending)
- [ ] Implement optimistic updates
- [ ] Show success/error notifications
- [ ] Add contribution preview

**Day 5: Testing & Polish**
- [ ] Write E2E test: create story → add contribution
- [ ] Test point deduction on contribution
- [ ] Test contribution validation
- [ ] Add loading states
- [ ] Add empty states (no stories, no contributions)
- [ ] Improve mobile responsiveness
- [ ] Add error boundaries

### Deliverables
- ✅ Story browsing interface
- ✅ Story creation form
- ✅ Story reading view
- ✅ Contribution editor
- ✅ Complete story user flow

### Acceptance Criteria
- Users can browse active stories
- Users can create new stories
- Users can read full stories
- Users can add contributions (if enough points)
- Points are deducted correctly
- Character limits enforced
- Mobile-friendly interface
- E2E test passes for story flow
- Test coverage >70%

---

## Sprint 7: Real-time Collaboration with Yjs (Week 8)

**Goal:** Implement CRDT-based real-time collaborative editing.

### Tasks

**Day 1-2: Yjs Setup**
- [ ] Install Yjs dependencies (`yjs`, `y-websocket`, `y-indexeddb`)
- [ ] Set up WebSocket provider through Supabase Realtime
- [ ] Create `lib/stories/collaboration.ts`
- [ ] Implement `CollaborativeStory` class
- [ ] Initialize Y.Doc for each story
- [ ] Set up IndexedDB persistence
- [ ] Test WebSocket connection

**Day 2-3: Editor Integration**
- [ ] Replace basic textarea with Yjs-bound editor
- [ ] Implement text insertion at cursor position
- [ ] Sync local changes to CRDT
- [ ] Receive and apply remote changes
- [ ] Handle concurrent edits gracefully
- [ ] Test with multiple browser windows

**Day 4: Awareness & Cursors**
- [ ] Implement awareness API for cursor positions
- [ ] Display active user cursors in editor
- [ ] Show user colors and names
- [ ] Add "Currently editing" indicator
- [ ] Implement cursor position syncing
- [ ] Test with multiple simultaneous users

**Day 5: Offline Support & Testing**
- [ ] Implement offline queue for contributions
- [ ] Sync queued contributions on reconnect
- [ ] Test offline → online transition
- [ ] Add connection status indicator
- [ ] Write tests for CRDT operations
- [ ] Test conflict resolution scenarios
- [ ] Performance test: 10 concurrent users

### Deliverables
- ✅ Yjs CRDT implementation
- ✅ Real-time collaborative editing
- ✅ Cursor awareness
- ✅ Offline support
- ✅ Working multi-user editor

### Acceptance Criteria
- Multiple users can edit simultaneously
- No conflicts or data loss
- Cursors visible for active users
- Offline edits sync on reconnect
- Connection status displayed
- Works with 10+ concurrent users
- Test coverage >60% (CRDT is complex)

---

## Sprint 8: Voting System & Challenges (Week 9)

**Goal:** Implement contribution voting and weekly challenges.

### Tasks

**Day 1-2: Voting System**
- [ ] Create `app/api/stories/[id]/contributions/[contributionId]/vote/route.ts`
- [ ] Implement vote submission logic
- [ ] Calculate vote weight based on user participation
- [ ] Implement vote limit (3 votes per period)
- [ ] Update contribution score
- [ ] Create `components/story/contribution-vote-button.tsx`
- [ ] Display vote counts on contributions
- [ ] Highlight user's votes
- [ ] Write tests for voting logic

**Day 2-3: Challenge System**
- [ ] Create `lib/gamification/challenges.ts`
- [ ] Define weekly challenge templates
- [ ] Implement `assignWeeklyChallenge()` function
- [ ] Create challenge assignment cron job
- [ ] Implement challenge progress tracking
- [ ] Create challenge completion detection
- [ ] Award bonus points on completion
- [ ] Write tests for challenge logic

**Day 4: Challenge UI**
- [ ] Create `components/dashboard/challenge-list.tsx`
- [ ] Display active challenges on dashboard
- [ ] Show progress bars for each challenge
- [ ] Add completion celebrations (confetti animation)
- [ ] Create `app/(auth)/challenges/page.tsx` for full list
- [ ] Show challenge history (completed challenges)
- [ ] Add challenge notifications

**Day 5: Testing & Integration**
- [ ] Write E2E test: vote on contribution
- [ ] Write E2E test: complete weekly challenge
- [ ] Test vote weight calculations
- [ ] Test challenge assignment logic
- [ ] Integration test: workout → challenge progress → completion
- [ ] Performance test voting system

### Deliverables
- ✅ Working voting system
- ✅ Challenge assignment and tracking
- ✅ Challenge UI on dashboard
- ✅ Challenge completion rewards

### Acceptance Criteria
- Users can vote on contributions (max 3 per period)
- Vote weight calculated correctly
- Challenges assigned weekly
- Challenge progress updates automatically
- Bonus points awarded on completion
- Voting UI intuitive and responsive
- Test coverage >75%

---

## Sprint 9: Fitbit Integration & Rate Limiting (Week 10)

**Goal:** Add Fitbit support and implement security measures.

### Tasks

**Day 1-2: Fitbit OAuth with PKCE**
- [ ] Register app with Fitbit API
- [ ] Create `lib/security/pkce.ts`
- [ ] Implement PKCE challenge generation
- [ ] Create `lib/fitness/fitbit/auth.ts`
- [ ] Implement `initiateFitbitAuth()` with PKCE
- [ ] Create `app/api/auth/fitbit/callback/route.ts`
- [ ] Handle 8-hour token expiry
- [ ] Test OAuth flow

**Day 2-3: Fitbit Activity Sync**
- [ ] Create `lib/fitness/fitbit/sync.ts`
- [ ] Implement `syncFitbitActivities()` function
- [ ] Normalize Fitbit activity data
- [ ] Handle rate limits (150 req/hour)
- [ ] Implement aggressive token refresh
- [ ] Add Fitbit connection UI
- [ ] Test with real Fitbit account

**Day 3-4: Rate Limiting**
- [ ] Install Upstash Redis dependencies
- [ ] Create Upstash Redis account
- [ ] Create `lib/security/rateLimit.ts`
- [ ] Implement rate limiters for:
  - Auth endpoints (5/15min)
  - API endpoints (100/min)
  - Workout endpoints (10/hour)
- [ ] Add rate limiting middleware
- [ ] Test rate limits with load testing tool
- [ ] Add rate limit headers to responses

**Day 5: Audit Logging**
- [ ] Create `audit_logs` table migration
- [ ] Create `lib/security/audit.ts`
- [ ] Implement `logAuditEvent()` function
- [ ] Add audit logging to sensitive operations:
  - User login/logout
  - Token refresh
  - Point transactions
  - Workout creation/deletion
  - Story contributions
- [ ] Create audit log viewer (admin only)
- [ ] Write tests for audit logging

### Deliverables
- ✅ Fitbit integration with PKCE
- ✅ Rate limiting on all endpoints
- ✅ Comprehensive audit logging
- ✅ Security hardening

### Acceptance Criteria
- Users can connect Fitbit
- Fitbit activities sync and award points
- Rate limits block excessive requests
- All sensitive operations logged
- No security vulnerabilities (npm audit passes)
- Test coverage >70% for security code

---

## Sprint 10: PWA Features & Mobile Optimization (Week 11)

**Goal:** Add Progressive Web App features and optimize for mobile.

### Tasks

**Day 1-2: Service Worker**
- [ ] Create `public/sw.js` service worker
- [ ] Implement cache-first strategy for static assets
- [ ] Implement network-first for API calls
- [ ] Add offline fallback page
- [ ] Register service worker in app
- [ ] Test offline functionality
- [ ] Implement cache versioning

**Day 2-3: Background Sync**
- [ ] Implement IndexedDB for offline workout queue
- [ ] Add background sync for workouts
- [ ] Sync queued workouts on reconnect
- [ ] Add sync status indicators
- [ ] Test offline workout logging
- [ ] Handle sync failures gracefully

**Day 3-4: Web App Manifest**
- [ ] Create `public/manifest.json`
- [ ] Add app icons (192x192, 512x512)
- [ ] Configure app shortcuts
- [ ] Set theme colors
- [ ] Add screenshots for app store
- [ ] Test "Add to Home Screen"
- [ ] Configure splash screen

**Day 4-5: Mobile Optimization**
- [ ] Optimize touch targets (min 44x44px)
- [ ] Improve mobile navigation
- [ ] Add pull-to-refresh
- [ ] Optimize images for mobile
- [ ] Test on real devices (iOS, Android)
- [ ] Fix mobile-specific bugs
- [ ] Run Lighthouse mobile audit (>90 score)

### Deliverables
- ✅ Service worker with offline support
- ✅ Background sync for workouts
- ✅ PWA manifest and icons
- ✅ Mobile-optimized interface
- ✅ Installable web app

### Acceptance Criteria
- App works offline
- Workouts can be logged offline
- App can be installed on home screen
- Mobile Lighthouse score >90
- Works on iOS and Android
- Touch targets meet accessibility standards

---

## Sprint 11: Monitoring, Analytics & Error Tracking (Week 12)

**Goal:** Implement comprehensive monitoring and analytics.

### Tasks

**Day 1-2: Sentry Integration**
- [ ] Create Sentry account and project
- [ ] Install `@sentry/nextjs`
- [ ] Configure `sentry.client.config.ts`
- [ ] Configure `sentry.server.config.ts`
- [ ] Add error boundaries in React components
- [ ] Test error reporting
- [ ] Configure source maps for production
- [ ] Set up performance monitoring
- [ ] Configure replay sessions

**Day 2-3: Vercel Analytics**
- [ ] Enable Vercel Analytics
- [ ] Install `@vercel/analytics`
- [ ] Add Analytics component to root layout
- [ ] Install `@vercel/speed-insights`
- [ ] Configure custom events tracking
- [ ] Create analytics dashboard

**Day 3-4: Custom Analytics**
- [ ] Create `lib/analytics/events.ts`
- [ ] Define key events to track:
  - Workout logged
  - Story contribution
  - Challenge completed
  - Fitness service connected
  - Points earned
- [ ] Implement event tracking functions
- [ ] Create internal analytics table
- [ ] Build analytics query API
- [ ] Create admin analytics dashboard

**Day 5: Performance Monitoring**
- [ ] Implement Web Vitals tracking
- [ ] Create performance budget
- [ ] Set up performance alerts
- [ ] Optimize slow queries
- [ ] Add database query monitoring
- [ ] Create performance dashboard

### Deliverables
- ✅ Sentry error tracking
- ✅ Vercel Analytics integration
- ✅ Custom event tracking
- ✅ Performance monitoring
- ✅ Analytics dashboard

### Acceptance Criteria
- All errors reported to Sentry
- User actions tracked in analytics
- Performance metrics monitored
- Alerts configured for critical issues
- Analytics dashboard accessible
- No performance regressions

---

## Sprint 12: Polish, Testing & Documentation (Week 13)

**Goal:** Final polish, comprehensive testing, and documentation for MVP launch.

### Tasks

**Day 1: Comprehensive Testing**
- [ ] Review test coverage (goal: >75% overall)
- [ ] Write missing unit tests
- [ ] Write E2E tests for all critical paths:
  - Sign up → workout → points → story contribution
  - Connect Strava → auto sync → points
  - Complete challenge → earn bonus
  - Real-time collaboration (2+ users)
- [ ] Load testing with k6 or Artillery
- [ ] Security testing (OWASP top 10)
- [ ] Accessibility testing (WCAG 2.1 AA)

**Day 2: Bug Fixes & Polish**
- [ ] Fix all critical bugs from testing
- [ ] Improve error messages
- [ ] Add helpful tooltips
- [ ] Improve loading states
- [ ] Add empty states everywhere
- [ ] Improve mobile UX
- [ ] Fix any console warnings/errors

**Day 3: Documentation**
- [ ] Update README.md with setup instructions
- [ ] Document environment variables
- [ ] Create API documentation
- [ ] Write user guide
- [ ] Document database schema
- [ ] Create deployment guide
- [ ] Add code comments where needed
- [ ] Update CLAUDE.md with final architecture

**Day 4: Legal & Compliance**
- [ ] Write Privacy Policy
- [ ] Write Terms of Service
- [ ] Add cookie consent banner
- [ ] Implement data export (GDPR compliance)
- [ ] Implement account deletion
- [ ] Add privacy settings page
- [ ] Review data encryption compliance

**Day 5: Pre-Launch Prep**
- [ ] Run final production build
- [ ] Test production deployment
- [ ] Configure production environment variables
- [ ] Set up production database backups
- [ ] Configure monitoring alerts
- [ ] Create launch checklist
- [ ] Prepare beta user invitations
- [ ] Create feedback collection system

### Deliverables
- ✅ Test coverage >75%
- ✅ All critical bugs fixed
- ✅ Complete documentation
- ✅ Privacy policy and ToS
- ✅ Production-ready application

### Acceptance Criteria
- All E2E tests pass
- Lighthouse score >90
- No critical security vulnerabilities
- Documentation complete and accurate
- Privacy policy and ToS reviewed
- Production deployment successful
- Beta users can be invited

---

## MVP Launch (Week 14)

**Goal:** Launch MVP to initial beta users and monitor.

### Week 14 Activities

**Beta Launch (Day 1)**
- [ ] Deploy to production
- [ ] Invite 5 initial beta users
- [ ] Send onboarding emails
- [ ] Monitor error rates
- [ ] Monitor performance metrics
- [ ] Be available for support

**Monitoring & Feedback (Days 2-3)**
- [ ] Daily check-ins with beta users
- [ ] Review Sentry errors
- [ ] Check analytics for usage patterns
- [ ] Monitor server performance
- [ ] Collect user feedback
- [ ] Fix critical bugs immediately

**Iteration (Days 4-5)**
- [ ] Implement quick wins from feedback
- [ ] Adjust point economy if needed
- [ ] Fix usability issues
- [ ] Optimize slow features
- [ ] Document learnings

### Success Metrics for MVP
- ✅ 5 users successfully onboarded
- ✅ Average of 3+ workouts logged per user per week
- ✅ At least 1 collaborative story created
- ✅ <1% error rate
- ✅ Page load time <2 seconds
- ✅ >80% user satisfaction

---

## Post-MVP: Iteration Roadmap (Weeks 15-18)

Based on user feedback, prioritize:

### Potential Features
- Social features (friend requests, direct messages)
- Leaderboards (weekly, monthly, all-time)
- Additional fitness integrations (Apple Health, Garmin)
- Story branching (multiple endings)
- AI-assisted story prompts
- Story categories and discovery
- Push notifications
- Email digests
- Mobile app (React Native)
- Story export (PDF, ePub)

### Prioritization Framework
1. **Must Have:** Critical bugs, security issues
2. **Should Have:** High-value features requested by >50% of users
3. **Nice to Have:** Polish and quality-of-life improvements
4. **Future:** Experimental features

---

## Sprint Best Practices

### Daily Practices
- Start each day with clear goals (3-5 tasks max)
- Commit code frequently (min 2x per day)
- Write tests alongside features (not after)
- Run full test suite before pushing
- Review own code before pushing
- Keep PRs small (<400 lines)

### End of Sprint
- Demo working features
- Retrospective (what worked, what didn't)
- Update sprint plan based on learnings
- Review velocity and adjust next sprint

### Code Quality Gates
- All tests pass
- Linting passes
- Type-check passes
- Test coverage doesn't decrease
- Lighthouse score maintained
- No new security vulnerabilities

### Documentation Standards
- Update README for setup changes
- Document new environment variables
- Add JSDoc comments for complex functions
- Update CLAUDE.md for architectural changes
- Keep API documentation in sync

---

## Risk Mitigation

### Technical Risks
- **Strava/Fitbit API changes:** Monitor API changelogs, implement graceful degradation
- **Supabase limitations:** Have migration plan to self-hosted Postgres
- **Real-time scaling:** Load test early, have fallback to polling
- **Security vulnerabilities:** Weekly `npm audit`, keep dependencies updated

### Product Risks
- **Low engagement:** A/B test point values, add social features
- **Gaming the system:** Monitor for patterns, adjust anti-gaming measures
- **Poor story quality:** Implement moderation, voting threshold for visibility

### Timeline Risks
- **Feature creep:** Stick to MVP, defer nice-to-haves
- **Blocking bugs:** Maintain bug backlog, fix critical bugs immediately
- **Technical debt:** Allocate 20% of each sprint to refactoring

---

## Definition of Done

A feature is "done" when:
- [ ] Code is written and reviewed
- [ ] Tests are written and passing (unit + integration)
- [ ] Documentation is updated
- [ ] UI is responsive and accessible
- [ ] Error handling is implemented
- [ ] Deployed to staging and tested
- [ ] Product owner approves (if applicable)

---

## Success Criteria for MVP

### Technical
- ✅ 0 critical bugs in production
- ✅ <2 second page load time (p95)
- ✅ >99% uptime
- ✅ <1% error rate
- ✅ Test coverage >75%
- ✅ Lighthouse score >90

### Product
- ✅ 5+ active beta users
- ✅ 3+ workouts logged per user per week
- ✅ 1+ collaborative story with 10+ contributions
- ✅ 80%+ positive user feedback
- ✅ Users return 3+ days per week

### Business
- ✅ Infrastructure costs <$50/month
- ✅ Can onboard new users without manual intervention
- ✅ Positive feedback from target audience
- ✅ Clear path to scaling to 50+ users

---

This sprint plan builds LoreFit methodically from infrastructure to MVP, following software engineering best practices. Each sprint has clear deliverables and acceptance criteria. Adjust timeline based on team size and velocity.

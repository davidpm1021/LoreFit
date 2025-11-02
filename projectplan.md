# Project Design Review: Fitness-Gated Collaborative Storytelling Web App

## Executive Summary

### Project Vision
A web application where users earn the right to contribute to collaborative stories through fitness achievements. Friends compete and collaborate by completing workouts to gain points, which they spend to add sentences to shared narratives with dynamic tone shifts and genre changes.

### Core Value Proposition
- **For users who want**: Accountability and motivation for fitness goals combined with creative expression
- **Unlike**: Traditional fitness trackers or writing platforms
- **This app**: Merges physical achievement with creative participation, making both more engaging
- **Key differentiator**: Story contribution rights must be earned through real-world fitness activities

### Target Audience
- Initial: 5-20 friends who enjoy both fitness and creative activities
- Characteristics: Mix of fitness levels, enjoy games like Jackbox and D&D, value humor and creativity
- Scale potential: Designed to support hundreds of users without architecture changes

---

## Technical Architecture

### Core Technology Stack

#### Frontend Framework
**Next.js 15 with App Router**
- TypeScript for type safety and better developer experience
- React 18+ for component architecture
- App Router for server components and improved performance
- Chosen for: Large ecosystem, excellent documentation, AI assistant training data

#### Styling System
**Tailwind CSS**
- Utility-first CSS framework
- Mobile-first responsive design
- Consistent design system
- Minimal CSS bundle size

#### Backend Infrastructure
**Supabase (Backend-as-a-Service)**
- PostgreSQL database with full SQL access
- Real-time subscriptions via WebSockets
- Built-in authentication with OAuth support
- Row-level security (RLS) for data protection
- Edge functions for serverless computing
- Free tier supports initial development and testing

#### State Management
**Three-layer approach:**
1. **Zustand**: Client-side UI state (modals, preferences, cursor positions)
2. **React Query (TanStack Query)**: Server state and caching
3. **Supabase Realtime**: Live collaboration features

#### Deployment Platform
**Vercel**
- Zero-config Next.js deployment
- Automatic preview deployments for PRs
- Edge network distribution
- Built-in analytics and monitoring

---

## Database Design

### Core Schema Structure

```sql
-- User Management
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  fitness_level TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  height_cm INTEGER,
  weight_kg DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Points and Gamification
CREATE TABLE user_points (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  current_balance INTEGER DEFAULT 0,
  total_earned INTEGER DEFAULT 0,
  total_spent INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  points_history JSONB DEFAULT '[]',
  weekly_goal INTEGER DEFAULT 100,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fitness Data
CREATE TABLE workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  workout_date DATE NOT NULL,
  workout_type TEXT NOT NULL,
  duration_minutes INTEGER,
  distance_km DECIMAL(6,2),
  calories_burned INTEGER,
  heart_rate_avg INTEGER,
  source TEXT NOT NULL, -- 'manual', 'strava', 'fitbit'
  external_id TEXT,
  raw_data JSONB,
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_external_workout UNIQUE(user_id, source, external_id)
);

CREATE INDEX idx_workouts_user_date ON workouts(user_id, workout_date DESC);
CREATE INDEX idx_workouts_date ON workouts(workout_date DESC);

-- API Sync Tracking
CREATE TABLE activity_sync (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  source TEXT NOT NULL,
  last_sync TIMESTAMPTZ,
  sync_status TEXT,
  access_token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  token_expires_at TIMESTAMPTZ,
  webhook_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Story Management
CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  author_id UUID REFERENCES profiles(id),
  genre TEXT NOT NULL,
  tone TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'complete', 'archived')),
  max_contributions INTEGER DEFAULT 100,
  content TEXT, -- Full rendered story
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Story Contributions
CREATE TABLE story_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  contributor_id UUID REFERENCES profiles(id),
  content TEXT NOT NULL CHECK (LENGTH(content) BETWEEN 10 AND 280),
  position INTEGER NOT NULL,
  points_spent INTEGER NOT NULL,
  contribution_type TEXT DEFAULT 'sentence', -- 'sentence', 'twist', 'character', 'ending'
  votes_received INTEGER DEFAULT 0,
  parent_contribution_id UUID REFERENCES story_contributions(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_story_position UNIQUE(story_id, position)
);

CREATE INDEX idx_contributions_story ON story_contributions(story_id, created_at);

-- Voting System
CREATE TABLE contribution_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contribution_id UUID REFERENCES story_contributions(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES profiles(id),
  vote_weight DECIMAL(3,2) DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_vote UNIQUE(contribution_id, voter_id)
);

-- User Baselines for Personalized Goals
CREATE TABLE user_baselines (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  avg_weekly_workouts DECIMAL(4,2),
  avg_workout_duration DECIMAL(5,2),
  avg_weekly_distance DECIMAL(6,2),
  avg_daily_steps INTEGER,
  baseline_calculated_at TIMESTAMPTZ,
  data_points INTEGER, -- Number of weeks used in calculation
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Challenges and Streaks
CREATE TABLE user_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  challenge_type TEXT NOT NULL,
  target_value INTEGER NOT NULL,
  current_value INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  points_reward INTEGER,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);
```

### Row-Level Security Policies

```sql
-- Users can only read their own fitness data
CREATE POLICY "Users read own workouts" ON workouts
  FOR SELECT USING (auth.uid() = user_id);

-- Users can see all stories but only edit their own contributions
CREATE POLICY "Public story reading" ON stories
  FOR SELECT USING (true);

CREATE POLICY "Users edit own contributions" ON story_contributions
  FOR ALL USING (auth.uid() = contributor_id);

-- Points are read-only except through functions
CREATE POLICY "Points read only" ON user_points
  FOR SELECT USING (true);
```

---

## Fitness API Integration Layer

### Primary Integration: Strava

#### OAuth 2.0 Flow Implementation
```typescript
// types/strava.ts
interface StravaTokens {
  access_token: string;
  refresh_token: string;
  expires_at: number;
  athlete: {
    id: number;
    firstname: string;
    lastname: string;
  };
}

// lib/strava/auth.ts
export async function initiateStravaAuth(userId: string): Promise<string> {
  const params = new URLSearchParams({
    client_id: process.env.STRAVA_CLIENT_ID!,
    response_type: 'code',
    redirect_uri: `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/strava/callback`,
    approval_prompt: 'auto',
    scope: 'activity:read_all,profile:read_all',
    state: userId // Pass user ID through OAuth flow
  });
  
  return `https://www.strava.com/oauth/authorize?${params}`;
}

// app/api/auth/strava/callback/route.ts
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');
  const userId = searchParams.get('state');
  
  // Exchange code for tokens
  const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: process.env.STRAVA_CLIENT_ID,
      client_secret: process.env.STRAVA_CLIENT_SECRET,
      code,
      grant_type: 'authorization_code'
    })
  });
  
  const tokens: StravaTokens = await tokenResponse.json();
  
  // Encrypt and store tokens
  await storeEncryptedTokens(userId, tokens);
  
  // Set up webhook subscription
  await setupStravaWebhook(userId, tokens.athlete.id);
  
  return NextResponse.redirect('/dashboard?connected=strava');
}
```

#### Data Sync Strategy
```typescript
// lib/strava/sync.ts
export async function syncStravaActivities(userId: string) {
  const tokens = await getDecryptedTokens(userId);
  
  // Check if token needs refresh (expires within 1 hour)
  if (tokens.expires_at < Date.now() / 1000 + 3600) {
    tokens = await refreshStravaTokens(tokens.refresh_token);
  }
  
  // Fetch recent activities
  const activities = await fetch(
    'https://www.strava.com/api/v3/athlete/activities?per_page=30',
    {
      headers: {
        'Authorization': `Bearer ${tokens.access_token}`
      }
    }
  ).then(r => r.json());
  
  // Normalize and store each activity
  for (const activity of activities) {
    await upsertWorkout({
      user_id: userId,
      external_id: `strava_${activity.id}`,
      source: 'strava',
      workout_date: activity.start_date_local,
      workout_type: normalizeActivityType(activity.type),
      duration_minutes: Math.round(activity.elapsed_time / 60),
      distance_km: activity.distance / 1000,
      calories_burned: estimateCalories(activity),
      raw_data: activity
    });
  }
}
```

### Secondary Integration: Fitbit

#### Fitbit-Specific Considerations
- OAuth 2.0 with PKCE required
- Tokens expire after 8 hours
- Rate limit: 150 requests/hour per user
- Intraday data requires manual approval

```typescript
// lib/fitbit/auth.ts
export async function initiateFitbitAuth(userId: string): Promise<string> {
  // Generate PKCE challenge
  const codeVerifier = generateRandomString(128);
  const codeChallenge = await sha256(codeVerifier);
  
  // Store verifier for callback
  await storeCodeVerifier(userId, codeVerifier);
  
  const params = new URLSearchParams({
    client_id: process.env.FITBIT_CLIENT_ID!,
    response_type: 'code',
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    scope: 'activity heartrate location nutrition profile settings sleep social weight',
    redirect_uri: `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/fitbit/callback`,
    state: userId
  });
  
  return `https://www.fitbit.com/oauth2/authorize?${params}`;
}
```

### Data Normalization Layer

```typescript
// lib/fitness/normalizer.ts
export interface NormalizedActivity {
  date: string;
  type: ActivityType;
  duration_minutes: number;
  distance_km?: number;
  calories?: number;
  heart_rate_avg?: number;
  intensity: 'low' | 'moderate' | 'high';
  raw_source: 'strava' | 'fitbit' | 'manual';
}

export function normalizeStravaActivity(activity: any): NormalizedActivity {
  return {
    date: activity.start_date_local,
    type: mapStravaType(activity.type),
    duration_minutes: Math.round(activity.elapsed_time / 60),
    distance_km: activity.distance ? activity.distance / 1000 : undefined,
    calories: activity.kilojoules ? Math.round(activity.kilojoules * 1.05) : undefined,
    heart_rate_avg: activity.average_heartrate,
    intensity: calculateIntensity(activity),
    raw_source: 'strava'
  };
}

export function normalizeFitbitActivity(activity: any): NormalizedActivity {
  return {
    date: activity.startTime,
    type: mapFitbitType(activity.activityName),
    duration_minutes: Math.round(activity.duration / 60000),
    distance_km: activity.distance,
    calories: activity.calories,
    heart_rate_avg: activity.averageHeartRate,
    intensity: mapFitbitIntensity(activity.activityLevel),
    raw_source: 'fitbit'
  };
}
```

---

## Gamification System

### Point Economy Design

#### Base Point Structure
```typescript
// lib/gamification/points.ts
export const POINT_VALUES = {
  // Base rewards
  WORKOUT_COMPLETED: 10,
  DAILY_GOAL_MET: 5,
  WEEKLY_GOAL_MET: 25,
  
  // Intensity bonuses
  EXCEEDED_BASELINE_10: 5,
  EXCEEDED_BASELINE_25: 10,
  EXCEEDED_BASELINE_50: 20,
  
  // Consistency rewards
  STREAK_3_DAYS: 15,
  STREAK_7_DAYS: 30,
  STREAK_30_DAYS: 100,
  
  // Social currency
  KUDOS_GIVEN: 1,
  KUDOS_RECEIVED: 2,
  
  // Story costs
  STORY_SENTENCE: 10,
  STORY_TWIST: 25,
  STORY_CHARACTER: 30,
  STORY_ENDING: 50,
  NARRATOR_ROLE: 75
} as const;

export async function calculateWorkoutPoints(
  workout: NormalizedActivity,
  userBaseline: UserBaseline
): Promise<number> {
  let points = POINT_VALUES.WORKOUT_COMPLETED;
  
  // Intensity bonus based on personal improvement
  const durationImprovement = workout.duration_minutes / userBaseline.avg_workout_duration;
  if (durationImprovement > 1.5) {
    points += POINT_VALUES.EXCEEDED_BASELINE_50;
  } else if (durationImprovement > 1.25) {
    points += POINT_VALUES.EXCEEDED_BASELINE_25;
  } else if (durationImprovement > 1.1) {
    points += POINT_VALUES.EXCEEDED_BASELINE_10;
  }
  
  // Activity variety bonus
  const recentActivities = await getRecentActivities(workout.user_id, 7);
  const uniqueTypes = new Set(recentActivities.map(a => a.type));
  if (uniqueTypes.size >= 3) {
    points += 5; // Variety bonus
  }
  
  // Cap maximum points to prevent gaming
  return Math.min(points, 50);
}
```

#### Personalized Baseline Calculation
```typescript
// lib/gamification/baseline.ts
export async function calculateUserBaseline(
  userId: string,
  weeksOfData: number = 4
): Promise<UserBaseline> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeksOfData * 7));
  
  const workouts = await supabase
    .from('workouts')
    .select('*')
    .eq('user_id', userId)
    .gte('workout_date', cutoffDate.toISOString())
    .order('workout_date', { ascending: false });
  
  // Group by week and calculate averages
  const weeklyStats = groupWorkoutsByWeek(workouts.data);
  
  return {
    user_id: userId,
    avg_weekly_workouts: calculateAverage(weeklyStats.map(w => w.count)),
    avg_workout_duration: calculateAverage(workouts.data.map(w => w.duration_minutes)),
    avg_weekly_distance: calculateAverage(weeklyStats.map(w => w.totalDistance)),
    baseline_calculated_at: new Date(),
    data_points: weeklyStats.length
  };
}

// Adaptive baseline that adjusts over time
export async function updateAdaptiveBaseline(
  userId: string,
  baseline: UserBaseline
): Promise<UserBaseline> {
  const recentWeek = await getLastWeekStats(userId);
  const alpha = 0.2; // Learning rate for exponential moving average
  
  return {
    ...baseline,
    avg_weekly_workouts: baseline.avg_weekly_workouts * (1 - alpha) + recentWeek.workouts * alpha,
    avg_workout_duration: baseline.avg_workout_duration * (1 - alpha) + recentWeek.avgDuration * alpha,
    avg_weekly_distance: baseline.avg_weekly_distance * (1 - alpha) + recentWeek.totalDistance * alpha,
    updated_at: new Date()
  };
}
```

### Challenge System

```typescript
// lib/gamification/challenges.ts
export interface Challenge {
  id: string;
  type: 'weekly' | 'monthly' | 'special';
  title: string;
  description: string;
  target: number;
  metric: 'workouts' | 'minutes' | 'distance' | 'calories';
  reward: number;
  starts_at: Date;
  ends_at: Date;
}

export const WEEKLY_CHALLENGES = [
  {
    title: "Consistency Champion",
    description: "Complete at least 4 workouts this week",
    target: 4,
    metric: 'workouts',
    reward: 30
  },
  {
    title: "Distance Warrior",
    description: "Cover 20km total this week",
    target: 20,
    metric: 'distance',
    reward: 35
  },
  {
    title: "Time Tracker",
    description: "Exercise for 150 minutes total",
    target: 150,
    metric: 'minutes',
    reward: 40
  }
];

export async function assignWeeklyChallenge(userId: string) {
  const userBaseline = await getUserBaseline(userId);
  const challenge = selectAppropriateChallenge(userBaseline, WEEKLY_CHALLENGES);
  
  await supabase.from('user_challenges').insert({
    user_id: userId,
    challenge_type: 'weekly',
    ...challenge,
    starts_at: startOfWeek(new Date()),
    ends_at: endOfWeek(new Date())
  });
}
```

---

## Collaborative Storytelling System

### Story Creation and Management

```typescript
// lib/stories/creation.ts
export interface StoryConfig {
  title: string;
  genre: 'fantasy' | 'sci-fi' | 'horror' | 'comedy' | 'mystery' | 'adventure';
  tone: 'serious' | 'comedic' | 'dark' | 'lighthearted' | 'chaotic';
  maxContributions: number;
  contributionRules: {
    minLength: number;
    maxLength: number;
    cooldownMinutes: number;
  };
}

export async function createStory(
  authorId: string,
  config: StoryConfig
): Promise<string> {
  // Generate initial prompt based on genre/tone
  const prompt = generateStoryPrompt(config.genre, config.tone);
  
  const { data: story } = await supabase
    .from('stories')
    .insert({
      author_id: authorId,
      title: config.title,
      genre: config.genre,
      tone: config.tone,
      max_contributions: config.maxContributions,
      content: prompt,
      metadata: {
        rules: config.contributionRules,
        prompt: prompt,
        participants: [authorId]
      }
    })
    .select()
    .single();
    
  // Initialize CRDT document
  await initializeCRDTDocument(story.id);
  
  return story.id;
}
```

### Real-time Collaboration with CRDT

```typescript
// lib/stories/collaboration.ts
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';
import { IndexeddbPersistence } from 'y-indexeddb';

export class CollaborativeStory {
  private ydoc: Y.Doc;
  private provider: WebsocketProvider;
  private text: Y.Text;
  private awareness: any;
  
  constructor(storyId: string, userId: string) {
    this.ydoc = new Y.Doc();
    
    // Initialize websocket connection through Supabase
    this.provider = new WebsocketProvider(
      process.env.NEXT_PUBLIC_WEBSOCKET_URL!,
      `story-${storyId}`,
      this.ydoc,
      {
        params: {
          auth: getSupabaseAuthToken()
        }
      }
    );
    
    // Set up local persistence for offline support
    new IndexeddbPersistence(`story-${storyId}`, this.ydoc);
    
    // Get shared text type
    this.text = this.ydoc.getText('content');
    
    // Set up awareness for cursor positions
    this.awareness = this.provider.awareness;
    this.awareness.setLocalStateField('user', {
      id: userId,
      color: generateUserColor(userId),
      cursor: null
    });
  }
  
  addContribution(
    text: string,
    position: number,
    contributorId: string,
    pointsCost: number
  ) {
    // Validate points availability
    if (!this.hasEnoughPoints(contributorId, pointsCost)) {
      throw new Error('Insufficient points');
    }
    
    // Insert text at position
    this.text.insert(position, text + ' ');
    
    // Record contribution in database
    this.recordContribution(text, position, contributorId, pointsCost);
    
    // Deduct points
    this.deductPoints(contributorId, pointsCost);
  }
  
  subscribeToChanges(callback: (event: any) => void) {
    this.text.observe(callback);
  }
  
  getCursors(): Map<string, CursorPosition> {
    const cursors = new Map();
    this.awareness.getStates().forEach((state, clientId) => {
      if (state.cursor) {
        cursors.set(clientId, state.cursor);
      }
    });
    return cursors;
  }
}
```

### Voting and Quality Control

```typescript
// lib/stories/voting.ts
export class VotingSystem {
  private votesPerUser: number = 3;
  private votingPeriodMinutes: number = 30;
  
  async submitVote(
    voterId: string,
    contributionId: string,
    weight: number = 1
  ): Promise<void> {
    // Check voting eligibility
    const userVotes = await this.getUserVotesInPeriod(voterId);
    if (userVotes.length >= this.votesPerUser) {
      throw new Error('Vote limit reached for this period');
    }
    
    // Calculate vote weight based on participation
    const voteWeight = await this.calculateVoteWeight(voterId);
    
    await supabase
      .from('contribution_votes')
      .upsert({
        contribution_id: contributionId,
        voter_id: voterId,
        vote_weight: voteWeight * weight
      });
      
    // Update contribution score
    await this.updateContributionScore(contributionId);
  }
  
  private async calculateVoteWeight(voterId: string): Promise<number> {
    const userStats = await getUserStats(voterId);
    
    // Base weight of 1.0
    let weight = 1.0;
    
    // Reduce weight for low participation
    const avgParticipation = await getAverageParticipation();
    if (userStats.totalPoints < avgParticipation * 0.5) {
      weight *= 0.5;
    }
    
    // Boost weight for consistent contributors
    if (userStats.weeklyStreak > 4) {
      weight *= 1.2;
    }
    
    return Math.min(weight, 2.0); // Cap at 2x
  }
}
```

### Story Prompt Generation

```typescript
// lib/stories/prompts.ts
export class StoryPromptGenerator {
  private genrePrompts = {
    fantasy: [
      "The ancient map revealed a path to...",
      "The dragon's last words were...",
      "When the magic failed, everyone realized..."
    ],
    'sci-fi': [
      "The ship's AI had been lying about...",
      "The transmission from Earth contained only...",
      "After the jump, they weren't in Kansas anymore..."
    ],
    comedy: [
      "Dave's superpower was incredibly specific:",
      "The aliens invaded Earth for one reason:",
      "The time machine only went back 5 minutes..."
    ]
  };
  
  private toneModifiers = {
    chaotic: [
      "Suddenly, everything was made of cheese.",
      "Then the narrator got fired mid-sentence.",
      "But nobody expected the Spanish Inquisition."
    ],
    dark: [
      "The laughter stopped when they realized...",
      "In the shadows, something stirred.",
      "The price of victory was..."
    ]
  };
  
  generatePrompt(genre: string, tone: string): string {
    const basePrompt = this.selectRandom(this.genrePrompts[genre]);
    
    if (Math.random() > 0.7) {
      // 30% chance to add tone modifier
      const modifier = this.selectRandom(this.toneModifiers[tone]);
      return `${basePrompt} ${modifier}`;
    }
    
    return basePrompt;
  }
  
  generateMidStoryPrompt(
    currentContext: string,
    desiredDirection?: string
  ): string {
    // Analyze current story for key elements
    const elements = this.extractKeyElements(currentContext);
    
    const prompts = [
      `Continue the story, but mention the ${elements.object}`,
      `Add a sentence about what ${elements.character} is thinking`,
      `Describe what happens when ${elements.action} goes wrong`,
      `Introduce a new character who knows about ${elements.mystery}`
    ];
    
    return this.selectRandom(prompts);
  }
}
```

---

## Core Application Features

### User Dashboard

```typescript
// app/dashboard/page.tsx
export default function Dashboard() {
  const { user } = useAuth();
  const { data: points } = useUserPoints(user.id);
  const { data: recentWorkouts } = useRecentWorkouts(user.id);
  const { data: activeStories } = useActiveStories();
  const { data: challenges } = useActiveChallenges(user.id);
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {/* Points and Level */}
      <PointsCard
        currentPoints={points.current_balance}
        level={points.level}
        nextLevelProgress={calculateLevelProgress(points)}
      />
      
      {/* Weekly Activity */}
      <WeeklyActivityChart
        workouts={recentWorkouts}
        goal={points.weekly_goal}
      />
      
      {/* Active Challenges */}
      <ChallengesList
        challenges={challenges}
        onChallengeClick={navigateToChallenge}
      />
      
      {/* Quick Actions */}
      <QuickActions>
        <LogWorkoutButton />
        <SyncFitnessDataButton />
        <JoinStoryButton />
      </QuickActions>
      
      {/* Recent Story Activity */}
      <StoryFeed
        stories={activeStories}
        userPoints={points.current_balance}
      />
      
      {/* Leaderboard */}
      <MiniLeaderboard />
    </div>
  );
}
```

### Manual Workout Entry

```typescript
// components/workout/ManualEntry.tsx
export function ManualWorkoutEntry({ onSuccess }: Props) {
  const [workout, setWorkout] = useState<WorkoutForm>({
    date: new Date(),
    type: 'running',
    duration: 30,
    distance: null,
    notes: ''
  });
  
  const mutation = useMutation({
    mutationFn: async (data: WorkoutForm) => {
      // Validate workout
      if (data.duration < 5) {
        throw new Error('Workout must be at least 5 minutes');
      }
      
      // Check for duplicates
      const existing = await checkForDuplicate(data);
      if (existing) {
        throw new Error('Similar workout already logged for this time');
      }
      
      // Save workout
      const workout = await saveWorkout({
        ...data,
        source: 'manual',
        user_id: user.id
      });
      
      // Calculate and award points
      const points = await calculateWorkoutPoints(workout);
      await awardPoints(user.id, points, `Manual workout: ${data.type}`);
      
      return { workout, points };
    },
    onSuccess: ({ workout, points }) => {
      toast.success(`Workout logged! +${points} points earned`);
      onSuccess?.(workout);
    }
  });
  
  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      mutation.mutate(workout);
    }}>
      {/* Form fields */}
    </form>
  );
}
```

### Story Contribution Interface

```typescript
// components/story/ContributionEditor.tsx
export function ContributionEditor({ 
  story,
  position,
  cost,
  onSubmit 
}: Props) {
  const [content, setContent] = useState('');
  const [charCount, setCharCount] = useState(0);
  const { points } = useUserPoints();
  const canAfford = points >= cost;
  
  const handleSubmit = async () => {
    if (!canAfford) {
      toast.error('Not enough points!');
      return;
    }
    
    if (content.length < 10 || content.length > 280) {
      toast.error('Contribution must be 10-280 characters');
      return;
    }
    
    await onSubmit({
      content,
      position,
      cost
    });
    
    setContent('');
  };
  
  return (
    <div className="relative">
      <textarea
        value={content}
        onChange={(e) => {
          setContent(e.target.value);
          setCharCount(e.target.value.length);
        }}
        placeholder="Add your sentence to the story..."
        className="w-full p-4 border rounded-lg resize-none"
        maxLength={280}
      />
      
      <div className="flex justify-between items-center mt-2">
        <span className={`text-sm ${charCount > 280 ? 'text-red-500' : 'text-gray-500'}`}>
          {charCount}/280 characters
        </span>
        
        <div className="flex items-center gap-4">
          <span className="text-sm font-medium">
            Cost: {cost} points
          </span>
          
          <button
            onClick={handleSubmit}
            disabled={!canAfford || charCount < 10 || charCount > 280}
            className={`px-4 py-2 rounded-lg font-medium transition
              ${canAfford 
                ? 'bg-blue-500 hover:bg-blue-600 text-white' 
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'}`}
          >
            Contribute ({cost} pts)
          </button>
        </div>
      </div>
      
      {!canAfford && (
        <div className="mt-2 p-3 bg-yellow-50 border border-yellow-200 rounded">
          <p className="text-sm text-yellow-800">
            You need {cost - points} more points. Complete a workout to earn points!
          </p>
        </div>
      )}
    </div>
  );
}
```

---

## Security Implementation

### Data Encryption

```typescript
// lib/security/encryption.ts
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex');

export function encryptToken(token: string): EncryptedData {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);
  
  let encrypted = cipher.update(token, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex')
  };
}

export function decryptToken(data: EncryptedData): string {
  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    KEY,
    Buffer.from(data.iv, 'hex')
  );
  
  decipher.setAuthTag(Buffer.from(data.authTag, 'hex'));
  
  let decrypted = decipher.update(data.encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}

// Store encrypted tokens in database
export async function storeTokens(
  userId: string,
  tokens: FitnessAPITokens
): Promise<void> {
  const encryptedAccess = encryptToken(tokens.access_token);
  const encryptedRefresh = encryptToken(tokens.refresh_token);
  
  await supabase
    .from('activity_sync')
    .upsert({
      user_id: userId,
      source: tokens.source,
      access_token_encrypted: JSON.stringify(encryptedAccess),
      refresh_token_encrypted: JSON.stringify(encryptedRefresh),
      token_expires_at: new Date(tokens.expires_at * 1000),
      updated_at: new Date()
    });
}
```

### OAuth 2.0 Security with PKCE

```typescript
// lib/security/pkce.ts
export class PKCEChallenge {
  private verifierLength = 128;
  
  generateVerifier(): string {
    const buffer = crypto.randomBytes(this.verifierLength);
    return base64url(buffer);
  }
  
  async generateChallenge(verifier: string): Promise<string> {
    const hash = crypto.createHash('sha256');
    hash.update(verifier);
    return base64url(hash.digest());
  }
  
  async validateChallenge(
    verifier: string,
    challenge: string
  ): Promise<boolean> {
    const expectedChallenge = await this.generateChallenge(verifier);
    return crypto.timingSafeEqual(
      Buffer.from(expectedChallenge),
      Buffer.from(challenge)
    );
  }
}

function base64url(buffer: Buffer): string {
  return buffer
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}
```

### Rate Limiting

```typescript
// lib/security/rateLimit.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL!,
  token: process.env.UPSTASH_REDIS_TOKEN!,
});

// Different rate limiters for different endpoints
export const rateLimiters = {
  auth: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(5, '15 m'), // 5 attempts per 15 minutes
    prefix: 'auth'
  }),
  
  api: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(100, '1 m'), // 100 requests per minute
    prefix: 'api'
  }),
  
  workout: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(10, '1 h'), // 10 workouts per hour
    prefix: 'workout'
  })
};

// Middleware
export async function rateLimit(
  request: Request,
  limiter: keyof typeof rateLimiters
): Promise<Response | null> {
  const identifier = request.headers.get('x-forwarded-for') ?? 'anonymous';
  const { success, limit, reset, remaining } = await rateLimiters[limiter].limit(identifier);
  
  if (!success) {
    return new Response('Too many requests', {
      status: 429,
      headers: {
        'X-RateLimit-Limit': limit.toString(),
        'X-RateLimit-Remaining': remaining.toString(),
        'X-RateLimit-Reset': new Date(reset).toISOString()
      }
    });
  }
  
  return null; // Continue processing
}
```

### Audit Logging

```typescript
// lib/security/audit.ts
export enum AuditAction {
  USER_LOGIN = 'USER_LOGIN',
  USER_LOGOUT = 'USER_LOGOUT',
  TOKEN_REFRESH = 'TOKEN_REFRESH',
  DATA_EXPORT = 'DATA_EXPORT',
  DATA_DELETE = 'DATA_DELETE',
  WORKOUT_CREATE = 'WORKOUT_CREATE',
  WORKOUT_DELETE = 'WORKOUT_DELETE',
  POINTS_EARNED = 'POINTS_EARNED',
  POINTS_SPENT = 'POINTS_SPENT',
  STORY_CONTRIBUTION = 'STORY_CONTRIBUTION'
}

export async function logAuditEvent(
  userId: string,
  action: AuditAction,
  metadata?: Record<string, any>
): Promise<void> {
  await supabase
    .from('audit_logs')
    .insert({
      user_id: userId,
      action,
      metadata: {
        ...metadata,
        ip: getClientIP(),
        user_agent: getUserAgent(),
        timestamp: new Date().toISOString()
      },
      created_at: new Date()
    });
}

// Automatic audit logging for sensitive operations
export function withAudit<T extends (...args: any[]) => Promise<any>>(
  action: AuditAction,
  fn: T
): T {
  return (async (...args: Parameters<T>) => {
    const userId = getCurrentUserId();
    const startTime = Date.now();
    
    try {
      const result = await fn(...args);
      
      await logAuditEvent(userId, action, {
        success: true,
        duration_ms: Date.now() - startTime,
        args: sanitizeArgs(args)
      });
      
      return result;
    } catch (error) {
      await logAuditEvent(userId, action, {
        success: false,
        error: error.message,
        duration_ms: Date.now() - startTime
      });
      
      throw error;
    }
  }) as T;
}
```

---

## Progressive Web App Configuration

### Service Worker Implementation

```javascript
// public/sw.js
const CACHE_VERSION = 'v1';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const DYNAMIC_CACHE = `dynamic-${CACHE_VERSION}`;
const OFFLINE_PAGE = '/offline.html';

// Assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/offline.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then(keys => {
        return Promise.all(
          keys
            .filter(key => key !== STATIC_CACHE && key !== DYNAMIC_CACHE)
            .map(key => caches.delete(key))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  
  // Skip non-GET requests
  if (request.method !== 'GET') return;
  
  // Handle API calls differently
  if (request.url.includes('/api/')) {
    event.respondWith(networkFirst(request));
  }
  // Static assets - cache first
  else if (request.url.match(/\.(js|css|png|jpg|jpeg|svg|gif)$/)) {
    event.respondWith(cacheFirst(request));
  }
  // HTML - network first
  else {
    event.respondWith(networkFirst(request));
  }
});

// Cache strategies
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return caches.match(OFFLINE_PAGE);
  }
}

async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    return cached || caches.match(OFFLINE_PAGE);
  }
}

// Background sync for offline workout submissions
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-workouts') {
    event.waitUntil(syncOfflineWorkouts());
  }
});

async function syncOfflineWorkouts() {
  const db = await openIndexedDB();
  const workouts = await db.getAllFromIndex('workouts', 'synced', 0);
  
  for (const workout of workouts) {
    try {
      const response = await fetch('/api/workouts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(workout)
      });
      
      if (response.ok) {
        workout.synced = 1;
        await db.put('workouts', workout);
      }
    } catch (error) {
      console.error('Failed to sync workout:', error);
    }
  }
}

// Push notifications
self.addEventListener('push', (event) => {
  const data = event.data?.json() || {};
  
  const options = {
    body: data.body || 'You have a new notification',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    data: data.url || '/',
    actions: data.actions || []
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'FitStory', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow(event.notification.data)
  );
});
```

### Web App Manifest

```json
// public/manifest.json
{
  "name": "FitStory: Fitness-Powered Storytelling",
  "short_name": "FitStory",
  "description": "Earn story contributions through fitness achievements",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait",
  "theme_color": "#3B82F6",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["fitness", "games", "social"],
  "screenshots": [
    {
      "src": "/screenshots/dashboard.png",
      "sizes": "1080x1920",
      "type": "image/png"
    },
    {
      "src": "/screenshots/story.png",
      "sizes": "1080x1920",
      "type": "image/png"
    }
  ],
  "shortcuts": [
    {
      "name": "Log Workout",
      "short_name": "Workout",
      "url": "/workout/new",
      "icons": [{ "src": "/icons/workout.png", "sizes": "96x96" }]
    },
    {
      "name": "Active Stories",
      "short_name": "Stories",
      "url": "/stories",
      "icons": [{ "src": "/icons/story.png", "sizes": "96x96" }]
    }
  ]
}
```

---

## Testing Strategy

### Unit Testing Setup

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'test/',
        '*.config.ts',
        '.next/',
        'public/'
      ]
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './'),
      '@/lib': path.resolve(__dirname, './lib'),
      '@/components': path.resolve(__dirname, './components')
    }
  }
});
```

### Integration Testing

```typescript
// test/integration/api/workouts.test.ts
import { createMocks } from 'node-mocks-http';
import { POST } from '@/app/api/workouts/route';
import { supabase } from '@/lib/supabase';

vi.mock('@/lib/supabase');

describe('POST /api/workouts', () => {
  it('creates workout and awards points', async () => {
    const { req, res } = createMocks({
      method: 'POST',
      body: {
        date: '2024-01-15',
        type: 'running',
        duration_minutes: 30,
        distance_km: 5
      }
    });
    
    // Mock user authentication
    vi.mocked(supabase.auth.getUser).mockResolvedValue({
      data: { user: { id: 'user-123' } }
    });
    
    // Mock database operations
    vi.mocked(supabase.from).mockImplementation((table) => ({
      insert: vi.fn().mockReturnThis(),
      select: vi.fn().mockResolvedValue({
        data: [{ id: 'workout-123', points_earned: 15 }]
      })
    }));
    
    await POST(req);
    
    expect(res._getStatusCode()).toBe(201);
    expect(res._getJSONData()).toMatchObject({
      workout: { id: 'workout-123' },
      points_earned: 15
    });
  });
  
  it('rejects duplicate workouts', async () => {
    // Mock existing workout
    vi.mocked(supabase.from).mockImplementation(() => ({
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockResolvedValue({
        data: [{ id: 'existing-workout' }]
      })
    }));
    
    const { req, res } = createMocks({
      method: 'POST',
      body: {
        date: '2024-01-15',
        type: 'running',
        duration_minutes: 30
      }
    });
    
    await POST(req);
    
    expect(res._getStatusCode()).toBe(409);
    expect(res._getJSONData()).toMatchObject({
      error: 'Similar workout already exists'
    });
  });
});
```

### End-to-End Testing

```typescript
// test/e2e/user-journey.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Complete User Journey', () => {
  test('new user can sign up, connect Strava, and earn points', async ({ page }) => {
    // Sign up
    await page.goto('/');
    await page.click('text=Get Started');
    
    await page.fill('[name=email]', 'test@example.com');
    await page.fill('[name=password]', 'TestPassword123!');
    await page.click('button[type=submit]');
    
    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Welcome');
    
    // Connect Strava (mocked OAuth flow)
    await page.click('text=Connect Strava');
    await page.waitForURL(/strava\.com/);
    
    // Mock Strava authorization
    await page.goto('/api/auth/strava/callback?code=mock_code&state=user_123');
    
    // Verify connection success
    await expect(page.locator('.toast-success')).toContainText('Strava connected');
    
    // Manual workout entry
    await page.click('text=Log Workout');
    await page.selectOption('[name=type]', 'running');
    await page.fill('[name=duration]', '30');
    await page.fill('[name=distance]', '5');
    await page.click('text=Save Workout');
    
    // Verify points awarded
    await expect(page.locator('[data-testid=points-balance]')).toContainText('15');
    
    // Join a story
    await page.click('text=Active Stories');
    await page.click('.story-card:first-child');
    
    // Add contribution
    await page.fill('[data-testid=contribution-input]', 'The hero decided to turn left.');
    await page.click('text=Contribute (10 pts)');
    
    // Verify contribution added and points deducted
    await expect(page.locator('.story-content')).toContainText('The hero decided to turn left');
    await expect(page.locator('[data-testid=points-balance]')).toContainText('5');
  });
  
  test('mobile responsive design', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    await page.goto('/dashboard');
    
    // Check mobile menu
    await page.click('[data-testid=mobile-menu-toggle]');
    await expect(page.locator('.mobile-menu')).toBeVisible();
    
    // Verify touch targets are appropriately sized
    const buttons = page.locator('button');
    const count = await buttons.count();
    
    for (let i = 0; i < count; i++) {
      const box = await buttons.nth(i).boundingBox();
      expect(box?.width).toBeGreaterThanOrEqual(44);
      expect(box?.height).toBeGreaterThanOrEqual(44);
    }
  });
});
```

---

## Deployment Configuration

### Environment Variables

```bash
# .env.local
# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname
DIRECT_URL=postgresql://user:password@host:5432/dbname

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key

# Fitness APIs
STRAVA_CLIENT_ID=your-strava-client-id
STRAVA_CLIENT_SECRET=your-strava-client-secret
FITBIT_CLIENT_ID=your-fitbit-client-id
FITBIT_CLIENT_SECRET=your-fitbit-client-secret

# Security
ENCRYPTION_KEY=64-character-hex-string
JWT_SECRET=your-jwt-secret
NEXTAUTH_SECRET=your-nextauth-secret

# App Configuration
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app
NEXT_PUBLIC_WEBSOCKET_URL=wss://your-app.supabase.co

# Monitoring
SENTRY_DSN=your-sentry-dsn
NEXT_PUBLIC_VERCEL_ANALYTICS_ID=your-analytics-id

# Redis (for rate limiting)
UPSTASH_REDIS_URL=your-redis-url
UPSTASH_REDIS_TOKEN=your-redis-token
```

### CI/CD Pipeline

```yaml
# .github/workflows/main.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run test:unit
      - run: npm run test:integration
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: coverage-report
          path: coverage/

  e2e:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run build
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm audit --audit-level=high
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  deploy-preview:
    needs: [lint, test]
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          scope: ${{ secrets.VERCEL_ORG_ID }}

  deploy-production:
    needs: [lint, test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          scope: ${{ secrets.VERCEL_ORG_ID }}
      
      - name: Create Sentry Release
        uses: getsentry/action-release@v1
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
          SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
        with:
          environment: production
          version: ${{ github.sha }}
```

---

## Monitoring and Analytics

### Performance Monitoring

```typescript
// lib/monitoring/performance.ts
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';
import * as Sentry from '@sentry/nextjs';

// Initialize Sentry
Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay()
  ]
});

// Custom performance metrics
export function trackMetric(
  name: string,
  value: number,
  tags?: Record<string, string>
) {
  // Send to Vercel Analytics
  if (window.analytics) {
    window.analytics.track(name, { value, ...tags });
  }
  
  // Send to Sentry
  Sentry.metrics.gauge(name, value, { tags });
}

// Track Core Web Vitals
export function reportWebVitals({
  id,
  name,
  label,
  value
}: NextWebVitalsMetric) {
  // Send to analytics
  trackMetric(name, value, { label });
  
  // Log poor performance
  const thresholds = {
    FCP: 2000,
    LCP: 2500,
    CLS: 0.1,
    FID: 100,
    TTFB: 600
  };
  
  if (value > thresholds[name]) {
    Sentry.captureMessage(`Poor ${name}: ${value}`, 'warning');
  }
}
```

### User Analytics

```typescript
// lib/analytics/events.ts
export const trackEvent = (
  event: string,
  properties?: Record<string, any>
) => {
  // Internal analytics
  logToDatabase(event, properties);
  
  // External services
  if (window.gtag) {
    window.gtag('event', event, properties);
  }
  
  if (window.mixpanel) {
    window.mixpanel.track(event, properties);
  }
};

// Predefined events
export const events = {
  WORKOUT_LOGGED: (type: string, duration: number, points: number) =>
    trackEvent('workout_logged', { type, duration, points }),
    
  STORY_CONTRIBUTION: (storyId: string, cost: number) =>
    trackEvent('story_contribution', { storyId, cost }),
    
  FITNESS_CONNECTED: (source: string) =>
    trackEvent('fitness_connected', { source }),
    
  POINTS_EARNED: (amount: number, source: string) =>
    trackEvent('points_earned', { amount, source }),
    
  CHALLENGE_COMPLETED: (challengeType: string, reward: number) =>
    trackEvent('challenge_completed', { challengeType, reward })
};
```

---

## Development Workflow

### Project Structure

```
fitness-storytelling-app/
├── app/                    # Next.js 15 app directory
│   ├── (auth)/            # Auth-required routes
│   │   ├── dashboard/     
│   │   ├── workouts/      
│   │   └── stories/       
│   ├── api/               # API routes
│   │   ├── auth/          
│   │   ├── workouts/      
│   │   └── stories/       
│   ├── layout.tsx         
│   └── page.tsx           
├── components/            # React components
│   ├── ui/               # Base UI components
│   ├── workout/          # Workout-related
│   ├── story/            # Story-related
│   └── dashboard/        # Dashboard widgets
├── lib/                   # Core logic
│   ├── supabase/         # Database client
│   ├── fitness/          # API integrations
│   ├── gamification/     # Points system
│   ├── stories/          # Story logic
│   └── security/         # Auth & encryption
├── hooks/                 # Custom React hooks
├── types/                 # TypeScript types
├── public/               # Static assets
├── test/                 # Test files
└── migrations/           # Database migrations
```

### Development Commands

```json
// package.json scripts
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "test": "npm run test:unit && npm run test:integration",
    "test:unit": "vitest run",
    "test:integration": "vitest run --config vitest.integration.config.ts",
    "test:e2e": "playwright test",
    "test:watch": "vitest",
    "db:migrate": "supabase migration up",
    "db:reset": "supabase db reset",
    "db:seed": "tsx scripts/seed.ts",
    "analyze": "ANALYZE=true npm run build",
    "format": "prettier --write .",
    "prepare": "husky install"
  }
}
```

### Code Quality Tools

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'plugin:security/recommended',
    'prettier'
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
    'security/detect-object-injection': 'off',
    'react/no-unescaped-entities': 'off'
  }
};

// prettier.config.js
module.exports = {
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'es5',
  printWidth: 100,
  plugins: ['prettier-plugin-tailwindcss']
};
```

---

## Scaling Considerations

### Performance Optimization

```typescript
// next.config.js
module.exports = {
  images: {
    domains: ['supabase.co', 'strava.com', 'fitbit.com'],
    formats: ['image/avif', 'image/webp']
  },
  
  // Code splitting
  experimental: {
    optimizeCss: true
  },
  
  // Compression
  compress: true,
  
  // Caching headers
  async headers() {
    return [
      {
        source: '/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable'
          }
        ]
      }
    ];
  }
};
```

### Database Optimization

```sql
-- Indexes for common queries
CREATE INDEX idx_workouts_user_date ON workouts(user_id, workout_date DESC);
CREATE INDEX idx_contributions_story ON story_contributions(story_id, position);
CREATE INDEX idx_points_history ON user_points USING GIN(points_history);

-- Partitioning for large tables (when needed)
CREATE TABLE workouts_2024 PARTITION OF workouts
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Materialized views for expensive aggregations
CREATE MATERIALIZED VIEW leaderboard_weekly AS
  SELECT 
    u.id,
    u.username,
    SUM(w.points_earned) as total_points,
    COUNT(w.id) as workout_count,
    DATE_TRUNC('week', CURRENT_DATE) as week_start
  FROM users u
  JOIN workouts w ON u.id = w.user_id
  WHERE w.workout_date >= DATE_TRUNC('week', CURRENT_DATE)
  GROUP BY u.id, u.username
  ORDER BY total_points DESC;

-- Refresh periodically
CREATE OR REPLACE FUNCTION refresh_leaderboard()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_weekly;
END;
$$ LANGUAGE plpgsql;

-- Schedule refresh every 5 minutes
SELECT cron.schedule('refresh-leaderboard', '*/5 * * * *', 'SELECT refresh_leaderboard()');
```

---

## Launch Checklist

### Pre-Launch Requirements

- [ ] **Security**
  - [ ] All API tokens encrypted at rest
  - [ ] OAuth 2.0 with PKCE implemented
  - [ ] Rate limiting configured
  - [ ] Audit logging active
  - [ ] Security headers configured
  - [ ] CORS properly set up
  
- [ ] **Testing**
  - [ ] Unit test coverage > 70%
  - [ ] Integration tests for all API endpoints
  - [ ] E2E tests for critical user journeys
  - [ ] Load testing completed
  - [ ] Security audit performed
  
- [ ] **Performance**
  - [ ] Lighthouse score > 90
  - [ ] Core Web Vitals passing
  - [ ] Images optimized
  - [ ] Code splitting implemented
  - [ ] Database queries optimized
  
- [ ] **Monitoring**
  - [ ] Error tracking configured (Sentry)
  - [ ] Analytics implemented
  - [ ] Performance monitoring active
  - [ ] Uptime monitoring configured
  - [ ] Log aggregation set up
  
- [ ] **Documentation**
  - [ ] API documentation complete
  - [ ] User guide written
  - [ ] Privacy policy published
  - [ ] Terms of service published
  - [ ] GDPR compliance documented

### Beta Launch (Week 1)

- [ ] Deploy to production environment
- [ ] Invite 5 initial friends
- [ ] Set up feedback collection system
- [ ] Monitor error rates and performance
- [ ] Daily check-ins with users

### Iteration Phase (Weeks 2-4)

- [ ] Fix critical bugs
- [ ] Adjust point economy based on usage
- [ ] Refine story prompts
- [ ] Optimize slow queries
- [ ] Implement requested features

### Public Launch Preparation

- [ ] Upgrade infrastructure for scale
- [ ] Implement user onboarding flow
- [ ] Create marketing website
- [ ] Set up customer support system
- [ ] Plan launch announcement

---

## Conclusion

This PDR provides a complete technical foundation for building a fitness-gated collaborative storytelling web application. The architecture prioritizes:

1. **Developer velocity** through modern tooling and frameworks
2. **Security** for handling fitness and health data
3. **Scalability** from 5 to 500+ users without rewrites
4. **User engagement** through carefully designed gamification
5. **Real-time collaboration** with conflict-free editing

The modular design allows for iterative development, starting with core features and expanding based on user feedback. Each component is designed to be testable, maintainable, and replaceable as the application evolves.

Start with the foundation (authentication, database, basic UI), add the fitness integration layer, implement the gamification system, then layer on the collaborative storytelling features. This progression ensures each piece is solid before building the next.
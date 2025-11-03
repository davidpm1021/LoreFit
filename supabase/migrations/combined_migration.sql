-- Create profiles table
-- This extends the auth.users table with additional user information

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  fitness_level TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  height_cm INTEGER CHECK (height_cm > 0 AND height_cm < 300),
  weight_kg DECIMAL(5,2) CHECK (weight_kg > 0 AND weight_kg < 500),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index on username for faster lookups
CREATE INDEX idx_profiles_username ON public.profiles(username);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles

-- Users can view all profiles (for leaderboards, story contributors, etc.)
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles
  FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete own profile"
  ON public.profiles
  FOR DELETE
  USING (auth.uid() = id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on profile changes
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Function to create profile automatically when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || SUBSTRING(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Add helpful comments
COMMENT ON TABLE public.profiles IS 'User profile information extending auth.users';
COMMENT ON COLUMN public.profiles.username IS 'Unique username for the user';
COMMENT ON COLUMN public.profiles.fitness_level IS 'Self-reported fitness level: beginner, intermediate, or advanced';
-- Create user_points table for gamification system

CREATE TABLE IF NOT EXISTS public.user_points (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  current_balance INTEGER DEFAULT 0 NOT NULL CHECK (current_balance >= 0),
  total_earned INTEGER DEFAULT 0 NOT NULL CHECK (total_earned >= 0),
  total_spent INTEGER DEFAULT 0 NOT NULL CHECK (total_spent >= 0),
  level INTEGER DEFAULT 1 NOT NULL CHECK (level >= 1),
  points_history JSONB DEFAULT '[]'::jsonb NOT NULL,
  weekly_goal INTEGER DEFAULT 100 NOT NULL CHECK (weekly_goal > 0),
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index for faster queries
CREATE INDEX idx_user_points_balance ON public.user_points(current_balance DESC);
CREATE INDEX idx_user_points_level ON public.user_points(level DESC);

-- Enable Row Level Security
ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_points

-- Everyone can view points (for leaderboards)
CREATE POLICY "Points are viewable by everyone"
  ON public.user_points
  FOR SELECT
  USING (true);

-- Only system can insert points (via trigger or function)
-- Users cannot directly insert their own points
CREATE POLICY "System can insert points"
  ON public.user_points
  FOR INSERT
  WITH CHECK (false); -- Will be done via triggers/functions

-- Only system can update points (via functions)
CREATE POLICY "System can update points"
  ON public.user_points
  FOR UPDATE
  USING (false) -- No direct updates allowed
  WITH CHECK (false);

-- Trigger to update updated_at
CREATE TRIGGER set_updated_at_points
  BEFORE UPDATE ON public.user_points
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Function to initialize user points when profile is created
CREATE OR REPLACE FUNCTION public.handle_new_profile_points()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_points (user_id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create points record when profile is created
CREATE TRIGGER on_profile_created_init_points
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_profile_points();

-- Function to award points (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION public.award_points(
  p_user_id UUID,
  p_amount INTEGER,
  p_source TEXT DEFAULT 'manual',
  p_description TEXT DEFAULT ''
)
RETURNS TABLE(new_balance INTEGER, new_total_earned INTEGER) AS $$
DECLARE
  v_new_balance INTEGER;
  v_new_total_earned INTEGER;
  v_history_entry JSONB;
BEGIN
  -- Validate amount is positive
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Points amount must be positive';
  END IF;

  -- Create history entry
  v_history_entry := jsonb_build_object(
    'amount', p_amount,
    'source', p_source,
    'description', p_description,
    'timestamp', NOW(),
    'type', 'earned'
  );

  -- Update points and get new values
  UPDATE public.user_points
  SET
    current_balance = current_balance + p_amount,
    total_earned = total_earned + p_amount,
    points_history = points_history || v_history_entry,
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING current_balance, total_earned
  INTO v_new_balance, v_new_total_earned;

  -- Return updated values
  RETURN QUERY SELECT v_new_balance, v_new_total_earned;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to spend points (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION public.spend_points(
  p_user_id UUID,
  p_amount INTEGER,
  p_purpose TEXT DEFAULT 'story_contribution',
  p_description TEXT DEFAULT ''
)
RETURNS TABLE(new_balance INTEGER, success BOOLEAN) AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance INTEGER;
  v_history_entry JSONB;
BEGIN
  -- Validate amount is positive
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Points amount must be positive';
  END IF;

  -- Get current balance
  SELECT current_balance INTO v_current_balance
  FROM public.user_points
  WHERE user_id = p_user_id;

  -- Check if user has enough points
  IF v_current_balance < p_amount THEN
    RETURN QUERY SELECT v_current_balance, false;
    RETURN;
  END IF;

  -- Create history entry
  v_history_entry := jsonb_build_object(
    'amount', -p_amount,
    'purpose', p_purpose,
    'description', p_description,
    'timestamp', NOW(),
    'type', 'spent'
  );

  -- Deduct points
  UPDATE public.user_points
  SET
    current_balance = current_balance - p_amount,
    total_spent = total_spent + p_amount,
    points_history = points_history || v_history_entry,
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING current_balance
  INTO v_new_balance;

  RETURN QUERY SELECT v_new_balance, true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add helpful comments
COMMENT ON TABLE public.user_points IS 'User points for gamification system';
COMMENT ON COLUMN public.user_points.current_balance IS 'Current available points';
COMMENT ON COLUMN public.user_points.total_earned IS 'Total points earned (all time)';
COMMENT ON COLUMN public.user_points.total_spent IS 'Total points spent (all time)';
COMMENT ON COLUMN public.user_points.points_history IS 'JSONB array of point transactions';
COMMENT ON FUNCTION public.award_points IS 'Award points to a user (bypasses RLS)';
COMMENT ON FUNCTION public.spend_points IS 'Spend user points with balance check (bypasses RLS)';
-- Create workouts table for fitness activity tracking

CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workout_date DATE NOT NULL,
  workout_type TEXT NOT NULL,
  duration_minutes INTEGER CHECK (duration_minutes > 0),
  distance_km DECIMAL(6,2) CHECK (distance_km >= 0),
  calories_burned INTEGER CHECK (calories_burned >= 0),
  heart_rate_avg INTEGER CHECK (heart_rate_avg >= 0 AND heart_rate_avg <= 250),
  source TEXT NOT NULL CHECK (source IN ('manual', 'strava', 'fitbit')),
  external_id TEXT,
  raw_data JSONB,
  points_earned INTEGER DEFAULT 0 NOT NULL CHECK (points_earned >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_external_workout UNIQUE(user_id, source, external_id)
);

-- Create indexes for common queries
CREATE INDEX idx_workouts_user_date ON public.workouts(user_id, workout_date DESC);
CREATE INDEX idx_workouts_date ON public.workouts(workout_date DESC);
CREATE INDEX idx_workouts_type ON public.workouts(workout_type);
CREATE INDEX idx_workouts_source ON public.workouts(source);

-- Enable Row Level Security
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workouts

-- Users can view their own workouts
CREATE POLICY "Users can view own workouts"
  ON public.workouts
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own workouts
CREATE POLICY "Users can insert own workouts"
  ON public.workouts
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own workouts
CREATE POLICY "Users can update own workouts"
  ON public.workouts
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own workouts
CREATE POLICY "Users can delete own workouts"
  ON public.workouts
  FOR DELETE
  USING (auth.uid() = user_id);

-- Add helpful comments
COMMENT ON TABLE public.workouts IS 'User workout activity data from all sources';
COMMENT ON COLUMN public.workouts.source IS 'Source of workout data: manual, strava, or fitbit';
COMMENT ON COLUMN public.workouts.external_id IS 'ID from external service (Strava/Fitbit)';
COMMENT ON COLUMN public.workouts.raw_data IS 'Original JSON data from external service';
COMMENT ON COLUMN public.workouts.points_earned IS 'Points awarded for this workout';
-- Create activity_sync table for OAuth token storage and sync tracking

CREATE TABLE IF NOT EXISTS public.activity_sync (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('strava', 'fitbit')),
  last_sync TIMESTAMPTZ,
  sync_status TEXT CHECK (sync_status IN ('active', 'error', 'revoked', 'pending')),
  access_token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  token_expires_at TIMESTAMPTZ,
  webhook_id TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_user_source UNIQUE(user_id, source)
);

-- Create indexes
CREATE INDEX idx_activity_sync_user ON public.activity_sync(user_id);
CREATE INDEX idx_activity_sync_status ON public.activity_sync(sync_status);
CREATE INDEX idx_activity_sync_expires ON public.activity_sync(token_expires_at) WHERE token_expires_at IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.activity_sync ENABLE ROW LEVEL SECURITY;

-- RLS Policies for activity_sync

-- Users can view their own sync status
CREATE POLICY "Users can view own sync status"
  ON public.activity_sync
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own sync records (when connecting services)
CREATE POLICY "Users can insert own sync records"
  ON public.activity_sync
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own sync records
CREATE POLICY "Users can update own sync records"
  ON public.activity_sync
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own sync records (to disconnect services)
CREATE POLICY "Users can delete own sync records"
  ON public.activity_sync
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE TRIGGER set_updated_at_activity_sync
  BEFORE UPDATE ON public.activity_sync
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Add helpful comments
COMMENT ON TABLE public.activity_sync IS 'OAuth token storage and sync status for fitness APIs';
COMMENT ON COLUMN public.activity_sync.access_token_encrypted IS 'AES-256-GCM encrypted access token';
COMMENT ON COLUMN public.activity_sync.refresh_token_encrypted IS 'AES-256-GCM encrypted refresh token';
COMMENT ON COLUMN public.activity_sync.sync_status IS 'Current sync status: active, error, revoked, or pending';
COMMENT ON COLUMN public.activity_sync.webhook_id IS 'Webhook subscription ID from the fitness service';
-- Create user_baselines table for personalized fitness goals

CREATE TABLE IF NOT EXISTS public.user_baselines (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  avg_weekly_workouts DECIMAL(4,2) CHECK (avg_weekly_workouts >= 0),
  avg_workout_duration DECIMAL(5,2) CHECK (avg_workout_duration >= 0),
  avg_weekly_distance DECIMAL(6,2) CHECK (avg_weekly_distance >= 0),
  avg_daily_steps INTEGER CHECK (avg_daily_steps >= 0),
  baseline_calculated_at TIMESTAMPTZ,
  data_points INTEGER CHECK (data_points >= 0),
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index
CREATE INDEX idx_user_baselines_calculated ON public.user_baselines(baseline_calculated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.user_baselines ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_baselines

-- Users can view their own baselines
CREATE POLICY "Users can view own baselines"
  ON public.user_baselines
  FOR SELECT
  USING (auth.uid() = user_id);

-- System can insert baselines
CREATE POLICY "System can insert baselines"
  ON public.user_baselines
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- System can update baselines
CREATE POLICY "System can update baselines"
  ON public.user_baselines
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE TRIGGER set_updated_at_baselines
  BEFORE UPDATE ON public.user_baselines
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Add helpful comments
COMMENT ON TABLE public.user_baselines IS 'Personalized fitness baselines for adaptive point calculation';
COMMENT ON COLUMN public.user_baselines.data_points IS 'Number of weeks of data used in calculation';
COMMENT ON COLUMN public.user_baselines.baseline_calculated_at IS 'When the baseline was last calculated';
-- Create user_challenges table for tracking weekly/monthly challenges

CREATE TABLE IF NOT EXISTS public.user_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  challenge_type TEXT NOT NULL CHECK (challenge_type IN ('weekly', 'monthly', 'special')),
  title TEXT NOT NULL,
  description TEXT,
  target_value INTEGER NOT NULL CHECK (target_value > 0),
  current_value INTEGER DEFAULT 0 NOT NULL CHECK (current_value >= 0),
  metric TEXT NOT NULL CHECK (metric IN ('workouts', 'minutes', 'distance', 'calories', 'points')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'expired')),
  points_reward INTEGER CHECK (points_reward >= 0),
  starts_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes for common queries
CREATE INDEX idx_challenges_user ON public.user_challenges(user_id);
CREATE INDEX idx_challenges_status ON public.user_challenges(status) WHERE status = 'active';
CREATE INDEX idx_challenges_ends ON public.user_challenges(ends_at) WHERE status = 'active';
CREATE INDEX idx_challenges_type ON public.user_challenges(challenge_type);

-- Enable Row Level Security
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_challenges

-- Users can view their own challenges
CREATE POLICY "Users can view own challenges"
  ON public.user_challenges
  FOR SELECT
  USING (auth.uid() = user_id);

-- System assigns challenges (users can't create their own directly)
CREATE POLICY "System can insert challenges"
  ON public.user_challenges
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- System updates challenge progress
CREATE POLICY "System can update challenges"
  ON public.user_challenges
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete abandoned challenges
CREATE POLICY "Users can delete own challenges"
  ON public.user_challenges
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to check and complete challenges
CREATE OR REPLACE FUNCTION public.check_challenge_completion(p_challenge_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_challenge RECORD;
  v_is_complete BOOLEAN;
BEGIN
  -- Get challenge details
  SELECT * INTO v_challenge
  FROM public.user_challenges
  WHERE id = p_challenge_id AND status = 'active';

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Check if target reached
  IF v_challenge.current_value >= v_challenge.target_value THEN
    -- Mark as completed
    UPDATE public.user_challenges
    SET
      status = 'completed',
      completed_at = NOW()
    WHERE id = p_challenge_id;

    -- Award points
    IF v_challenge.points_reward > 0 THEN
      PERFORM public.award_points(
        v_challenge.user_id,
        v_challenge.points_reward,
        'challenge_completion',
        'Completed: ' || v_challenge.title
      );
    END IF;

    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to expire old challenges
CREATE OR REPLACE FUNCTION public.expire_old_challenges()
RETURNS INTEGER AS $$
DECLARE
  v_expired_count INTEGER;
BEGIN
  UPDATE public.user_challenges
  SET status = 'expired'
  WHERE status = 'active'
    AND ends_at < NOW()
    AND current_value < target_value;

  GET DIAGNOSTICS v_expired_count = ROW_COUNT;
  RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add helpful comments
COMMENT ON TABLE public.user_challenges IS 'User challenges for additional motivation and rewards';
COMMENT ON COLUMN public.user_challenges.metric IS 'What is being tracked: workouts, minutes, distance, calories, or points';
COMMENT ON COLUMN public.user_challenges.target_value IS 'Goal value to reach';
COMMENT ON COLUMN public.user_challenges.current_value IS 'Current progress toward goal';
COMMENT ON FUNCTION public.check_challenge_completion IS 'Check if challenge is complete and award points';
COMMENT ON FUNCTION public.expire_old_challenges IS 'Mark expired challenges as failed';

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

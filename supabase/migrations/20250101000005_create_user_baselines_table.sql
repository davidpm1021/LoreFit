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

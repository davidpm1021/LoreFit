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

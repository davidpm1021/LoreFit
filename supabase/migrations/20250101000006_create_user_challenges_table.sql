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

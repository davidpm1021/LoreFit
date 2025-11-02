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

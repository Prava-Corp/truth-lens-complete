-- ============================================================
-- User Scans Table — per-user scan history & analytics
-- Run this in Supabase SQL Editor (Dashboard → SQL → New query)
-- ============================================================

CREATE TABLE IF NOT EXISTS user_scans (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  barcode text NOT NULL,
  product_name text NOT NULL,
  brand text,
  category text,
  health_score int,
  verdict text CHECK (verdict IN ('Good', 'Moderate', 'Poor')),
  additives_count int DEFAULT 0,
  intent text DEFAULT 'checked' CHECK (intent IN ('checked', 'consumed', 'avoided')),
  scanned_at timestamptz DEFAULT now()
);

-- Index for fast user-specific queries
CREATE INDEX idx_user_scans_user_id ON user_scans(user_id);
CREATE INDEX idx_user_scans_scanned_at ON user_scans(scanned_at DESC);
CREATE INDEX idx_user_scans_user_date ON user_scans(user_id, scanned_at DESC);

-- Row Level Security: users can only access their own scans
ALTER TABLE user_scans ENABLE ROW LEVEL SECURITY;

-- Policy: authenticated users can read their own scans
CREATE POLICY "Users can read own scans"
  ON user_scans FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: authenticated users can insert their own scans
CREATE POLICY "Users can insert own scans"
  ON user_scans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: authenticated users can update their own scans (for changing intent)
CREATE POLICY "Users can update own scans"
  ON user_scans FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: authenticated users can delete their own scans
CREATE POLICY "Users can delete own scans"
  ON user_scans FOR DELETE
  USING (auth.uid() = user_id);

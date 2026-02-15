-- Migration v2: Add purchase tracking + fix duplicates
-- Run this in Supabase SQL Editor

-- 1. Add purchase_date column
ALTER TABLE user_scans ADD COLUMN IF NOT EXISTS purchase_date DATE DEFAULT NULL;

-- 2. Remove duplicate rows (keep most recent per user+barcode)
DELETE FROM user_scans a
USING user_scans b
WHERE a.id < b.id
  AND a.user_id = b.user_id
  AND a.barcode = b.barcode;

-- 3. Add unique constraint to prevent future duplicates
ALTER TABLE user_scans DROP CONSTRAINT IF EXISTS unique_user_barcode;
ALTER TABLE user_scans ADD CONSTRAINT unique_user_barcode UNIQUE (user_id, barcode);

-- 4. Update intent constraint to include 'purchased'
ALTER TABLE user_scans DROP CONSTRAINT IF EXISTS user_scans_intent_check;
ALTER TABLE user_scans ADD CONSTRAINT user_scans_intent_check
  CHECK (intent IN ('checked', 'consumed', 'avoided', 'purchased'));

-- 5. Index for purchase history queries
CREATE INDEX IF NOT EXISTS idx_user_scans_purchase ON user_scans(user_id, purchase_date DESC);

-- 6. Index for weekly activity queries
CREATE INDEX IF NOT EXISTS idx_user_scans_scanned_at ON user_scans(user_id, scanned_at DESC);

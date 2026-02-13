-- ============================================================
-- FSSAI Additives Table for Truth Lens
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- Create the fssai_additives table
CREATE TABLE IF NOT EXISTS fssai_additives (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,          -- E-number (e.g., "E211", "E924")
    name VARCHAR(200) NOT NULL,                 -- Common name
    fssai_status VARCHAR(20) NOT NULL           -- "permitted", "restricted", "banned", "not_listed"
        CHECK (fssai_status IN ('permitted', 'restricted', 'banned', 'not_listed')),
    category VARCHAR(100) NOT NULL,             -- Functional class (colour, preservative, etc.)
    max_limit VARCHAR(100) DEFAULT 'unknown',   -- Max permitted level (ppm or GMP)
    health_concern TEXT DEFAULT '',              -- Plain-English health concern
    fssai_note TEXT DEFAULT '',                  -- Regulatory note from FSSAI
    severity INTEGER DEFAULT 0                  -- 0 (safe) to 5 (most dangerous)
        CHECK (severity >= 0 AND severity <= 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast lookups by code
CREATE INDEX IF NOT EXISTS idx_fssai_additives_code ON fssai_additives (code);
CREATE INDEX IF NOT EXISTS idx_fssai_additives_status ON fssai_additives (fssai_status);

-- Enable Row Level Security
ALTER TABLE fssai_additives ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Allow anyone (anon role) to READ fssai_additives
-- This is reference data, safe to expose publicly
CREATE POLICY "Allow public read access to fssai_additives"
    ON fssai_additives
    FOR SELECT
    USING (true);

-- RLS Policy: Only authenticated users can INSERT/UPDATE
CREATE POLICY "Allow authenticated insert to fssai_additives"
    ON fssai_additives
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update to fssai_additives"
    ON fssai_additives
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Also allow anon to insert (for seeding via anon key)
-- Remove this policy later if you want write-protection
CREATE POLICY "Allow anon insert to fssai_additives"
    ON fssai_additives
    FOR INSERT
    TO anon
    WITH CHECK (true);

CREATE POLICY "Allow anon update to fssai_additives"
    ON fssai_additives
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_fssai_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fssai_updated_at
    BEFORE UPDATE ON fssai_additives
    FOR EACH ROW
    EXECUTE FUNCTION update_fssai_updated_at();

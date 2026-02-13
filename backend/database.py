"""
Database connection and configuration for Supabase
Compatible with supabase-py 2.x
"""
import os
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_KEY in environment variables")

# Create Supabase client
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print(f"✅ Connected to Supabase: {SUPABASE_URL}")

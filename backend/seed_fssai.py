"""
Seed script: Push FSSAI regulation data from local dictionary to Supabase.

Usage:
    python seed_fssai.py

This reads from fssai_regulations.py (the local database) and upserts
all entries into the Supabase `fssai_additives` table.

Prerequisites:
    1. Run supabase_schema_fssai.sql in Supabase SQL Editor first
    2. Ensure .env has valid SUPABASE_URL and SUPABASE_KEY
"""
import os
import sys
from dotenv import load_dotenv

load_dotenv()

# Import the local FSSAI database
from fssai_regulations import FSSAI_DATABASE


def seed_fssai():
    """Push all FSSAI data to Supabase."""
    from supabase import create_client

    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")

    if not url or not key:
        print("❌ Missing SUPABASE_URL or SUPABASE_KEY in .env")
        sys.exit(1)

    print(f"🔗 Connecting to Supabase: {url}")
    client = create_client(url, key)

    total = len(FSSAI_DATABASE)
    success = 0
    errors = 0

    print(f"📦 Seeding {total} FSSAI additive records...\n")

    for code, info in FSSAI_DATABASE.items():
        record = {
            "code": code.upper(),
            "name": info["name"],
            "fssai_status": info["fssai_status"],
            "category": info["category"],
            "max_limit": info.get("max_limit", "unknown"),
            "health_concern": info.get("health_concern", ""),
            "fssai_note": info.get("fssai_note", ""),
            "severity": info.get("severity", 0),
        }

        try:
            # Upsert: insert if new, update if code already exists
            result = client.table("fssai_additives").upsert(
                record,
                on_conflict="code"
            ).execute()

            status_icon = {
                "banned": "🔴",
                "restricted": "🟡",
                "permitted": "🟢",
                "not_listed": "⚪",
            }.get(info["fssai_status"], "❓")

            print(f"  {status_icon} {code:8s} {info['name'][:40]:40s} [{info['fssai_status']}]")
            success += 1

        except Exception as e:
            print(f"  ❌ {code:8s} FAILED: {e}")
            errors += 1

    print(f"\n{'='*60}")
    print(f"✅ Seeded: {success}/{total} records")
    if errors:
        print(f"❌ Errors: {errors}")
    print(f"{'='*60}")

    # Verify by reading back
    print("\n🔍 Verifying... reading back from Supabase:")
    try:
        verify = client.table("fssai_additives").select("code, name, fssai_status").order("severity", desc=True).limit(5).execute()
        print(f"   Top 5 by severity:")
        for row in verify.data:
            print(f"   • {row['code']} - {row['name']} [{row['fssai_status']}]")

        count = client.table("fssai_additives").select("code", count="exact").execute()
        print(f"\n   Total records in Supabase: {count.count}")
    except Exception as e:
        print(f"   ⚠️  Verification read failed: {e}")
        print(f"   (Data was likely seeded, but anon key may lack read RLS policy)")


if __name__ == "__main__":
    seed_fssai()

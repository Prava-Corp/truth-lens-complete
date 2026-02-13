"""
Product Service - Core business logic for product ingestion and retrieval

Optimized: First-scan products return immediately from OFF data.
Supabase ingestion runs in a background thread so the user doesn't wait.
"""
import threading
from typing import Optional, Dict, Any, List
from database import supabase
from open_food_facts import fetch_product_from_off, extract_additives


# ============================================================
# CHECK IF BARCODE EXISTS
# ============================================================
def barcode_exists(barcode: str) -> bool:
    """Check if barcode already exists in database"""
    result = supabase.table("barcodes") \
        .select("id") \
        .eq("barcode_number", barcode) \
        .execute()
    return len(result.data) > 0


# ============================================================
# GET PRODUCT ID BY BARCODE
# ============================================================
def get_product_id_by_barcode(barcode: str) -> Optional[str]:
    """Get product_id from barcode"""
    result = supabase.table("barcodes") \
        .select("product_id") \
        .eq("barcode_number", barcode) \
        .single() \
        .execute()
    if result.data:
        return result.data["product_id"]
    return None


# ============================================================
# BUILD RESPONSE DIRECTLY FROM OFF DATA (FAST PATH)
# ============================================================
def build_response_from_off(barcode: str, off_product: Dict[str, Any]) -> Dict[str, Any]:
    """
    Build API response directly from Open Food Facts data.
    No Supabase queries needed — returns in ~0ms after OFF fetch.
    """
    additive_codes = extract_additives(off_product)
    ingredients_text = (
        off_product.get("ingredients_text")
        or off_product.get("ingredients_text_en")
        or "Ingredients not available"
    )

    # Build flags from OFF data directly (basic regulatory info)
    flags = []
    # OFF sometimes has "additives_old_tags" with risk info — use what we can
    # We'll rely on FSSAI enrichment in main.py for detailed flags

    return {
        "barcode": barcode,
        "product_name": off_product.get("product_name") or "Unknown Product",
        "brand": off_product.get("brands"),
        "category": off_product.get("categories"),
        "ingredients": ingredients_text,
        "additives": additive_codes,
        "flags": flags,
    }


# ============================================================
# BACKGROUND SUPABASE INGESTION
# ============================================================
def _background_ingest(barcode: str, off_product: Dict[str, Any]):
    """
    Save product data to Supabase in a background thread.
    This runs AFTER the response is already sent to the user.
    """
    try:
        print(f"🔄 [Background] Saving {barcode} to Supabase...")

        # Insert product
        product = {
            "product_name": off_product.get("product_name") or "Unknown Product",
            "brand_name": off_product.get("brands"),
            "category": off_product.get("categories"),
            "off_product_id": off_product.get("id"),
        }
        result = supabase.table("products").insert(product).execute()
        product_id = result.data[0]["id"]

        # Insert barcode link
        supabase.table("barcodes").insert({
            "barcode_number": barcode,
            "barcode_type": "EAN",
            "product_id": product_id,
            "source": "openfoodfacts",
            "confidence_score": 0.8,
            "off_url": off_product.get("url"),
        }).execute()

        # Insert ingredients
        raw_text = off_product.get("ingredients_text") or off_product.get("ingredients_text_en")
        if raw_text:
            supabase.table("ingredient_raw").insert({
                "product_id": product_id,
                "raw_text": raw_text,
                "source": "openfoodfacts",
            }).execute()

        # Insert additives (batched — fewer round-trips)
        additive_codes = extract_additives(off_product)
        if additive_codes:
            _insert_additives_batched(product_id, additive_codes)
            _apply_regulatory_flags(product_id)

        # Log scan
        supabase.table("scans").insert({
            "product_id": product_id,
            "barcode_number": barcode,
            "intent": "checked",
        }).execute()

        print(f"✅ [Background] Saved {off_product.get('product_name')} to Supabase")

    except Exception as e:
        print(f"⚠️ [Background] Supabase save failed (non-fatal): {e}")


def start_background_ingest(barcode: str, off_product: Dict[str, Any]):
    """Launch background thread for Supabase ingestion."""
    thread = threading.Thread(
        target=_background_ingest,
        args=(barcode, off_product),
        daemon=True,
    )
    thread.start()


# ============================================================
# INSERT ADDITIVES (BATCHED)
# ============================================================
def _insert_additives_batched(product_id: str, additive_codes: List[str]):
    """Insert additives with fewer DB round-trips."""
    for code in additive_codes:
        try:
            # Upsert additive (insert if not exists)
            existing = supabase.table("additives") \
                .select("id") \
                .eq("code", code) \
                .execute()

            if existing.data:
                additive_id = existing.data[0]["id"]
            else:
                result = supabase.table("additives").insert({
                    "code": code,
                    "name": code,
                    "category": "unknown",
                }).execute()
                additive_id = result.data[0]["id"]

            # Link to product (skip if already linked)
            existing_link = supabase.table("product_additives") \
                .select("id") \
                .eq("product_id", product_id) \
                .eq("additive_id", additive_id) \
                .execute()

            if not existing_link.data:
                supabase.table("product_additives").insert({
                    "product_id": product_id,
                    "additive_id": additive_id,
                }).execute()
        except Exception as e:
            print(f"⚠️ Could not link additive {code}: {e}")

    print(f"✅ Linked {len(additive_codes)} additives to product {product_id}")


# ============================================================
# APPLY REGULATORY FLAGS
# ============================================================
def _apply_regulatory_flags(product_id: str):
    """Apply regulatory flags based on additives."""
    try:
        additives = supabase.table("product_additives") \
            .select("additive_id, additives(code)") \
            .eq("product_id", product_id) \
            .execute()

        for row in additives.data:
            additive_id = row["additive_id"]
            code = row["additives"]["code"]

            rules = supabase.table("regulatory_rules") \
                .select("status, region, restriction_notes") \
                .eq("additive_id", additive_id) \
                .execute()

            for rule in rules.data:
                supabase.table("product_flags") \
                    .delete() \
                    .eq("product_id", product_id) \
                    .eq("region", rule["region"]) \
                    .eq("flag_type", rule["status"]) \
                    .execute()

                supabase.table("product_flags").insert({
                    "product_id": product_id,
                    "region": rule["region"],
                    "flag_type": rule["status"],
                    "explanation": f"Contains {code}: {rule['restriction_notes']}",
                }).execute()

        print(f"✅ Applied regulatory flags for product {product_id}")
    except Exception as e:
        print(f"⚠️ Regulatory flags failed (non-fatal): {e}")


# ============================================================
# MAIN FAST-PATH FUNCTION
# ============================================================
def fetch_and_respond(barcode: str) -> Optional[Dict[str, Any]]:
    """
    Fast path: Fetch product and return response immediately.

    1. Check Supabase cache first (instant for repeat scans)
    2. If not cached, fetch from OFF and return directly
    3. Background-save to Supabase for next time

    Returns:
        Product data dict or None if not found anywhere
    """
    print(f"\n{'='*50}")
    print(f"🔍 Processing barcode: {barcode}")
    print(f"{'='*50}")

    # Fast path: already in database
    if barcode_exists(barcode):
        print(f"⚡ Cache hit — returning from Supabase")
        response = get_product_response(barcode)
        # Log scan in background
        try:
            product_id = get_product_id_by_barcode(barcode)
            if product_id:
                threading.Thread(
                    target=lambda: supabase.table("scans").insert({
                        "product_id": product_id,
                        "barcode_number": barcode,
                        "intent": "checked",
                    }).execute(),
                    daemon=True,
                ).start()
        except Exception:
            pass
        return response

    # Slow path: fetch from Open Food Facts (~2-5s)
    print(f"🌐 Cache miss — fetching from Open Food Facts...")
    off_product = fetch_product_from_off(barcode)

    if not off_product:
        print(f"❌ Product not found for barcode: {barcode}")
        return None

    # Build response directly from OFF data (instant)
    response = build_response_from_off(barcode, off_product)
    print(f"⚡ Returning response immediately for: {off_product.get('product_name')}")

    # Save to Supabase in background (user doesn't wait)
    start_background_ingest(barcode, off_product)

    return response


# ============================================================
# LEGACY: GET PRODUCT RESPONSE FROM DB
# ============================================================
def get_product_response(barcode: str) -> Optional[Dict[str, Any]]:
    """
    Get complete product data from Supabase (for cached products).
    """
    barcode_row = supabase.table("barcodes") \
        .select("product_id, products(product_name, brand_name, category)") \
        .eq("barcode_number", barcode) \
        .single() \
        .execute()

    if not barcode_row.data:
        return None

    product_id = barcode_row.data["product_id"]
    product = barcode_row.data["products"]

    # Get ingredients
    ingredients = supabase.table("ingredient_raw") \
        .select("raw_text") \
        .eq("product_id", product_id) \
        .execute()

    ingredients_text = "Ingredients not available"
    if ingredients.data:
        ingredients_text = ingredients.data[0]["raw_text"]

    # Get additives
    additives = supabase.table("product_additives") \
        .select("additives(code)") \
        .eq("product_id", product_id) \
        .execute()

    additive_codes = [a["additives"]["code"] for a in additives.data]

    # Get flags
    flags = supabase.table("product_flags") \
        .select("flag_type, explanation, region") \
        .eq("product_id", product_id) \
        .execute()

    return {
        "barcode": barcode,
        "product_name": product["product_name"],
        "brand": product.get("brand_name"),
        "category": product.get("category"),
        "ingredients": ingredients_text,
        "additives": additive_codes,
        "flags": flags.data,
    }

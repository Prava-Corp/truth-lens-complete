"""
FSSAI (Food Safety and Standards Authority of India) Regulation Database
Based on FSS (Food Products Standards and Food Additives) Regulations, 2011
and subsequent amendments through 2025.

Sources:
- FSSAI Appendix A: List of Food Additives
- FSSAI Chapter 3: Substances Added to Food
- FSSAI ban orders (Potassium Bromate 2016, etc.)

Each additive has:
- ins_number: INS/E number
- name: Common name
- fssai_status: "permitted" | "restricted" | "banned" | "not_listed"
- category: Functional class (colour, preservative, emulsifier, etc.)
- max_limit: Maximum permitted level (ppm or GMP)
- food_categories: Which food types it's allowed in (if restricted)
- health_concern: Plain-English health concern
- fssai_note: Regulatory note from FSSAI
"""

from typing import Optional, Dict, List


# Status levels
PERMITTED = "permitted"       # Allowed with GMP or specified limits
RESTRICTED = "restricted"     # Allowed only in certain food categories or with strict limits
BANNED = "banned"             # Banned in India by FSSAI
NOT_LISTED = "not_listed"     # Not in FSSAI approved list (effectively not permitted)


FSSAI_DATABASE: Dict[str, dict] = {
    # ================================================================
    # BANNED ADDITIVES
    # ================================================================
    "E924": {
        "name": "Potassium Bromate",
        "fssai_status": BANNED,
        "category": "flour treatment agent",
        "max_limit": "0 (banned)",
        "health_concern": "Classified as possible human carcinogen (IARC Group 2B). Linked to kidney and thyroid cancer. Banned by FSSAI in 2016.",
        "fssai_note": "Removed from list of permitted additives by FSSAI order dated 20 June 2016. Was previously used in bread and bakery products.",
        "severity": 5,
    },
    "E924B": {
        "name": "Calcium Bromate",
        "fssai_status": BANNED,
        "category": "flour treatment agent",
        "max_limit": "0 (banned)",
        "health_concern": "Similar carcinogenic concerns as Potassium Bromate.",
        "fssai_note": "Banned along with Potassium Bromate in 2016.",
        "severity": 5,
    },
    "E917": {
        "name": "Potassium Iodate",
        "fssai_status": BANNED,
        "category": "flour treatment agent",
        "max_limit": "0 (banned in bread)",
        "health_concern": "Excess iodine intake can cause thyroid disorders. CSE study found residues in 84% of tested bread brands.",
        "fssai_note": "Banned as bread additive by FSSAI in 2016. Still permitted for salt iodization under separate regulations.",
        "severity": 4,
    },

    # ================================================================
    # PERMITTED COLOURS (8 synthetic colours allowed by FSSAI)
    # ================================================================
    "E102": {
        "name": "Tartrazine (Yellow)",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "May cause hyperactivity in children. Can trigger allergic reactions, especially in aspirin-sensitive individuals.",
        "fssai_note": "Permitted synthetic colour. Must be declared on label. Limited to 100 ppm in most food categories.",
        "severity": 3,
    },
    "E110": {
        "name": "Sunset Yellow FCF",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Linked to hyperactivity in children. EU requires warning label. May cause allergic reactions.",
        "fssai_note": "Permitted synthetic colour in India. Max 100 ppm.",
        "severity": 3,
    },
    "E122": {
        "name": "Carmoisine (Azorubine)",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Azo dye linked to hyperactivity in children. May cause allergic reactions.",
        "fssai_note": "One of 8 FSSAI-permitted synthetic colours.",
        "severity": 3,
    },
    "E124": {
        "name": "Ponceau 4R",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Azo dye. Linked to hyperactivity. Banned in USA and Norway.",
        "fssai_note": "Permitted in India but banned in several countries. Max 100 ppm.",
        "severity": 3,
    },
    "E127": {
        "name": "Erythrosine",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Contains iodine. High doses may affect thyroid function.",
        "fssai_note": "Permitted synthetic colour. Restricted to specific food categories.",
        "severity": 3,
    },
    "E129": {
        "name": "Allura Red AC",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Linked to hyperactivity in children. Some studies suggest genotoxicity.",
        "fssai_note": "Permitted synthetic colour in India. Max 100 ppm.",
        "severity": 3,
    },
    "E132": {
        "name": "Indigotine (Indigo Carmine)",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "May cause nausea and high blood pressure in sensitive individuals.",
        "fssai_note": "Permitted synthetic colour. Max 100 ppm.",
        "severity": 2,
    },
    "E133": {
        "name": "Brilliant Blue FCF",
        "fssai_status": RESTRICTED,
        "category": "synthetic colour",
        "max_limit": "100 ppm",
        "health_concern": "Generally well tolerated. Rare allergic reactions reported.",
        "fssai_note": "Permitted synthetic colour. Max 100 ppm.",
        "severity": 1,
    },

    # Non-permitted colours (banned)
    "E142": {
        "name": "Green S",
        "fssai_status": BANNED,
        "category": "synthetic colour",
        "max_limit": "0 (not permitted)",
        "health_concern": "Not approved by FSSAI. Banned synthetic colour in India.",
        "fssai_note": "Not in FSSAI list of 8 permitted synthetic colours.",
        "severity": 4,
    },

    # Natural colours (generally permitted)
    "E100": {
        "name": "Curcumin (Turmeric)",
        "fssai_status": PERMITTED,
        "category": "natural colour",
        "max_limit": "GMP",
        "health_concern": "Natural colour from turmeric. Generally safe. Traditional Indian ingredient.",
        "fssai_note": "Natural colour, permitted at GMP levels.",
        "severity": 0,
    },
    "E160A": {
        "name": "Beta-Carotene",
        "fssai_status": PERMITTED,
        "category": "natural colour",
        "max_limit": "GMP",
        "health_concern": "Natural pigment found in carrots. Safe at food levels.",
        "fssai_note": "Permitted natural colour.",
        "severity": 0,
    },
    "E150D": {
        "name": "Caramel Colour (Class IV - Sulphite Ammonia)",
        "fssai_status": RESTRICTED,
        "category": "colour",
        "max_limit": "varies by food category",
        "health_concern": "Contains 4-methylimidazole (4-MEI), classified as possibly carcinogenic. Found in colas and dark beverages.",
        "fssai_note": "Permitted but classified separately from natural caramel. Used in carbonated beverages.",
        "severity": 3,
    },

    # ================================================================
    # PRESERVATIVES
    # ================================================================
    "E200": {
        "name": "Sorbic Acid",
        "fssai_status": PERMITTED,
        "category": "preservative (Class II)",
        "max_limit": "1000 ppm (varies)",
        "health_concern": "Generally safe. One of the safest preservatives available.",
        "fssai_note": "Class II preservative. Permitted in various food categories up to 1000 ppm.",
        "severity": 0,
    },
    "E202": {
        "name": "Potassium Sorbate",
        "fssai_status": PERMITTED,
        "category": "preservative (Class II)",
        "max_limit": "1000 ppm (varies)",
        "health_concern": "Salt of sorbic acid. Generally safe.",
        "fssai_note": "Class II preservative. Widely permitted.",
        "severity": 0,
    },
    "E210": {
        "name": "Benzoic Acid",
        "fssai_status": RESTRICTED,
        "category": "preservative (Class II)",
        "max_limit": "300 ppm",
        "health_concern": "Can form benzene (a carcinogen) when combined with Vitamin C (ascorbic acid). FSSAI limits to 300 ppm.",
        "fssai_note": "Class II preservative. Max 300 ppm. Caution with vitamin C containing products.",
        "severity": 3,
    },
    "E211": {
        "name": "Sodium Benzoate",
        "fssai_status": RESTRICTED,
        "category": "preservative (Class II)",
        "max_limit": "300 ppm",
        "health_concern": "Can form benzene with vitamin C. Linked to hyperactivity in children when combined with artificial colours.",
        "fssai_note": "Class II preservative. Max 300 ppm. Widely used in beverages and sauces.",
        "severity": 3,
    },
    "E220": {
        "name": "Sulphur Dioxide",
        "fssai_status": RESTRICTED,
        "category": "preservative (Class II)",
        "max_limit": "varies (70-350 ppm)",
        "health_concern": "Can trigger severe asthma attacks. Must be declared on label. Destroys vitamin B1.",
        "fssai_note": "Class II preservative. Mandatory labelling if >10 ppm. Used in dried fruits, wine, pickles.",
        "severity": 3,
    },
    "E223": {
        "name": "Sodium Metabisulphite",
        "fssai_status": RESTRICTED,
        "category": "preservative (Class II)",
        "max_limit": "varies by product",
        "health_concern": "Sulphite - can trigger asthma and allergic reactions. Must be declared as allergen.",
        "fssai_note": "Permitted as dough conditioner and preservative. Must be declared on label.",
        "severity": 3,
    },
    "E250": {
        "name": "Sodium Nitrite",
        "fssai_status": RESTRICTED,
        "category": "preservative",
        "max_limit": "200 ppm (in meat products)",
        "health_concern": "Can form nitrosamines (carcinogens) during cooking. Used in processed meats. IARC links processed meat to colorectal cancer.",
        "fssai_note": "Permitted only in certain meat products. Strict limits apply.",
        "severity": 4,
    },
    "E251": {
        "name": "Sodium Nitrate",
        "fssai_status": RESTRICTED,
        "category": "preservative",
        "max_limit": "500 ppm (in meat)",
        "health_concern": "Converts to nitrite in the body. Same nitrosamine concerns as sodium nitrite.",
        "fssai_note": "Permitted in meat products with limits.",
        "severity": 3,
    },

    # ================================================================
    # ANTIOXIDANTS
    # ================================================================
    "E320": {
        "name": "BHA (Butylated Hydroxyanisole)",
        "fssai_status": RESTRICTED,
        "category": "antioxidant",
        "max_limit": "200 ppm",
        "health_concern": "Classified as possibly carcinogenic (IARC Group 2B). Endocrine disruptor concerns.",
        "fssai_note": "Permitted antioxidant. Max 200 ppm individually or combined with BHT.",
        "severity": 4,
    },
    "E321": {
        "name": "BHT (Butylated Hydroxytoluene)",
        "fssai_status": RESTRICTED,
        "category": "antioxidant",
        "max_limit": "200 ppm",
        "health_concern": "Possible endocrine disruptor. Some animal studies show tumour promotion.",
        "fssai_note": "Permitted antioxidant. Max 200 ppm combined with BHA.",
        "severity": 3,
    },
    "E319": {
        "name": "TBHQ (Tert-Butylhydroquinone)",
        "fssai_status": RESTRICTED,
        "category": "antioxidant",
        "max_limit": "200 ppm",
        "health_concern": "High doses can cause nausea, delirium. Some studies suggest immune system effects.",
        "fssai_note": "Permitted antioxidant. Max 200 ppm.",
        "severity": 3,
    },
    "E300": {
        "name": "Ascorbic Acid (Vitamin C)",
        "fssai_status": PERMITTED,
        "category": "antioxidant",
        "max_limit": "GMP",
        "health_concern": "Safe. Essential nutrient (Vitamin C).",
        "fssai_note": "Permitted antioxidant at GMP levels.",
        "severity": 0,
    },
    "E306": {
        "name": "Tocopherol (Vitamin E)",
        "fssai_status": PERMITTED,
        "category": "antioxidant",
        "max_limit": "GMP",
        "health_concern": "Safe. Essential nutrient (Vitamin E).",
        "fssai_note": "Permitted antioxidant at GMP levels.",
        "severity": 0,
    },

    # ================================================================
    # EMULSIFIERS & STABILIZERS
    # ================================================================
    "E322": {
        "name": "Lecithin",
        "fssai_status": PERMITTED,
        "category": "emulsifier",
        "max_limit": "GMP",
        "health_concern": "Generally safe. Natural emulsifier from soy or eggs. Soy allergen risk.",
        "fssai_note": "Permitted emulsifier at GMP. Must declare soy origin for allergen labelling.",
        "severity": 1,
    },
    "E330": {
        "name": "Citric Acid",
        "fssai_status": PERMITTED,
        "category": "acidity regulator",
        "max_limit": "GMP",
        "health_concern": "Safe. Naturally found in citrus fruits.",
        "fssai_note": "Permitted acidity regulator at GMP.",
        "severity": 0,
    },
    "E412": {
        "name": "Guar Gum",
        "fssai_status": PERMITTED,
        "category": "thickener/stabilizer",
        "max_limit": "GMP",
        "health_concern": "Generally safe. May cause digestive discomfort in large amounts.",
        "fssai_note": "Permitted thickener. India is the world's largest producer of guar gum.",
        "severity": 0,
    },
    "E415": {
        "name": "Xanthan Gum",
        "fssai_status": PERMITTED,
        "category": "thickener/stabilizer",
        "max_limit": "GMP",
        "health_concern": "Generally safe. May cause bloating in large amounts.",
        "fssai_note": "Permitted thickener at GMP.",
        "severity": 0,
    },
    "E407": {
        "name": "Carrageenan",
        "fssai_status": PERMITTED,
        "category": "thickener/stabilizer",
        "max_limit": "GMP",
        "health_concern": "Some studies link to gut inflammation. Debated safety, but generally recognized as safe.",
        "fssai_note": "Permitted stabilizer at GMP. Used in dairy products.",
        "severity": 2,
    },
    "E471": {
        "name": "Mono- and Diglycerides of Fatty Acids",
        "fssai_status": PERMITTED,
        "category": "emulsifier",
        "max_limit": "GMP",
        "health_concern": "Generally safe. May be from animal or plant sources — vegetarian status unclear unless specified.",
        "fssai_note": "Permitted emulsifier. FSSAI requires veg/non-veg declaration.",
        "severity": 1,
    },

    # ================================================================
    # FLAVOUR ENHANCERS
    # ================================================================
    "E621": {
        "name": "Monosodium Glutamate (MSG)",
        "fssai_status": RESTRICTED,
        "category": "flavour enhancer",
        "max_limit": "not specified (GMP in most categories)",
        "health_concern": "May cause 'Chinese Restaurant Syndrome' (headache, flushing, sweating) in sensitive people. FSSAI restricts in infant food.",
        "fssai_note": "Permitted in most food categories. Banned in infant food and food for young children. Must be declared on label.",
        "severity": 2,
    },
    "E627": {
        "name": "Disodium Guanylate",
        "fssai_status": RESTRICTED,
        "category": "flavour enhancer",
        "max_limit": "GMP",
        "health_concern": "Should be avoided by gout sufferers (purine metabolism). Often used with MSG.",
        "fssai_note": "Permitted flavour enhancer. Not for infant food.",
        "severity": 2,
    },
    "E631": {
        "name": "Disodium Inosinate",
        "fssai_status": RESTRICTED,
        "category": "flavour enhancer",
        "max_limit": "GMP",
        "health_concern": "Avoid if gout-prone. Often combined with MSG and E627.",
        "fssai_note": "Permitted flavour enhancer. Not for infant food.",
        "severity": 2,
    },

    # ================================================================
    # RAISING AGENTS
    # ================================================================
    "E500": {
        "name": "Sodium Bicarbonate (Baking Soda)",
        "fssai_status": PERMITTED,
        "category": "raising agent",
        "max_limit": "GMP",
        "health_concern": "Safe. Common household ingredient.",
        "fssai_note": "Permitted raising agent at GMP.",
        "severity": 0,
    },
    "E501": {
        "name": "Potassium Carbonate",
        "fssai_status": PERMITTED,
        "category": "raising agent",
        "max_limit": "GMP",
        "health_concern": "Safe. Used in baking.",
        "fssai_note": "Permitted raising agent at GMP.",
        "severity": 0,
    },
    "E503": {
        "name": "Ammonium Carbonate",
        "fssai_status": PERMITTED,
        "category": "raising agent",
        "max_limit": "GMP",
        "health_concern": "Safe. Evaporates during baking.",
        "fssai_note": "Permitted raising agent at GMP.",
        "severity": 0,
    },

    # ================================================================
    # SWEETENERS
    # ================================================================
    "E951": {
        "name": "Aspartame",
        "fssai_status": RESTRICTED,
        "category": "artificial sweetener",
        "max_limit": "varies by product",
        "health_concern": "WHO/IARC classified as possibly carcinogenic (Group 2B) in 2023. Phenylketonuria (PKU) patients must avoid.",
        "fssai_note": "Permitted in sugar-free products. Must carry PKU warning. FSSAI monitoring post-IARC classification.",
        "severity": 3,
    },
    "E950": {
        "name": "Acesulfame Potassium (Ace-K)",
        "fssai_status": RESTRICTED,
        "category": "artificial sweetener",
        "max_limit": "varies by product",
        "health_concern": "Some studies suggest it may affect gut microbiome. Generally considered safe at permitted levels.",
        "fssai_note": "Permitted artificial sweetener.",
        "severity": 2,
    },
    "E955": {
        "name": "Sucralose",
        "fssai_status": PERMITTED,
        "category": "artificial sweetener",
        "max_limit": "varies by product",
        "health_concern": "Generally considered safe. Some concerns about effects when heated.",
        "fssai_note": "Permitted artificial sweetener.",
        "severity": 1,
    },

    # ================================================================
    # ACIDITY REGULATORS
    # ================================================================
    "E338": {
        "name": "Phosphoric Acid",
        "fssai_status": RESTRICTED,
        "category": "acidity regulator",
        "max_limit": "varies by product",
        "health_concern": "High intake may reduce calcium absorption and affect bone density. Common in colas.",
        "fssai_note": "Permitted acidity regulator. Primary use in carbonated beverages.",
        "severity": 2,
    },
    "E451": {
        "name": "Triphosphate (Pentasodium/Pentapotassium)",
        "fssai_status": RESTRICTED,
        "category": "emulsifier/stabilizer",
        "max_limit": "varies by product",
        "health_concern": "Excessive phosphate intake linked to cardiovascular and kidney issues.",
        "fssai_note": "Permitted with limits. Used in processed meat and noodles.",
        "severity": 2,
    },
}


# ================================================================
# Supabase-backed lookup functions
# Falls back to local FSSAI_DATABASE if Supabase is unavailable
# ================================================================

_supabase_client = None
_use_supabase = False


def init_fssai_supabase():
    """
    Initialize Supabase client for FSSAI lookups.
    Call this once at startup. If it fails, local fallback is used.
    """
    global _supabase_client, _use_supabase

    try:
        import os
        from dotenv import load_dotenv
        load_dotenv()

        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        demo = os.getenv("DEMO_MODE", "false").lower() == "true"

        if demo:
            print("📋 FSSAI: Using local database (demo mode)")
            _use_supabase = False
            return

        if url and key:
            from supabase import create_client
            _supabase_client = create_client(url, key)
            # Quick test: try to read one row
            test = _supabase_client.table("fssai_additives").select("code").limit(1).execute()
            if test.data is not None:
                _use_supabase = True
                print(f"📋 FSSAI: Connected to Supabase ({len(test.data)} test rows)")
            else:
                print("📋 FSSAI: Supabase returned no data, using local fallback")
                _use_supabase = False
        else:
            print("📋 FSSAI: No Supabase credentials, using local database")
            _use_supabase = False
    except Exception as e:
        print(f"📋 FSSAI: Supabase init failed ({e}), using local fallback")
        _use_supabase = False


def _lookup_from_supabase(code: str) -> Optional[dict]:
    """Fetch a single additive from Supabase by code."""
    try:
        result = _supabase_client.table("fssai_additives").select(
            "code, name, fssai_status, category, max_limit, health_concern, fssai_note, severity"
        ).eq("code", code.upper().strip()).limit(1).execute()

        if result.data and len(result.data) > 0:
            return result.data[0]
        return None
    except Exception as e:
        print(f"⚠️  FSSAI Supabase lookup failed for {code}: {e}")
        return None


def _batch_lookup_from_supabase(codes: List[str]) -> Dict[str, dict]:
    """Fetch multiple additives from Supabase in one query."""
    try:
        normalized = [c.upper().strip() for c in codes]
        result = _supabase_client.table("fssai_additives").select(
            "code, name, fssai_status, category, max_limit, health_concern, fssai_note, severity"
        ).in_("code", normalized).execute()

        return {row["code"]: row for row in (result.data or [])}
    except Exception as e:
        print(f"⚠️  FSSAI Supabase batch lookup failed: {e}")
        return {}


def check_additive_fssai(code: str) -> Optional[dict]:
    """
    Check an additive code against FSSAI regulations.
    Uses Supabase if available, otherwise falls back to local database.

    Args:
        code: Additive E/INS number (e.g., 'E211', 'E102')

    Returns:
        FSSAI regulation info dict or None if not in database
    """
    normalized = code.upper().strip()

    if _use_supabase:
        return _lookup_from_supabase(normalized)

    # Local fallback
    return FSSAI_DATABASE.get(normalized)


def check_product_fssai(additive_codes: List[str]) -> List[dict]:
    """
    Check all additives in a product against FSSAI regulations.
    Uses batch Supabase query for efficiency.

    Returns list of FSSAI findings sorted by severity (most concerning first).
    """
    findings = []

    # Batch lookup if using Supabase
    if _use_supabase and additive_codes:
        supabase_results = _batch_lookup_from_supabase(additive_codes)
    else:
        supabase_results = {}

    for code in additive_codes:
        normalized = code.upper().strip()

        if _use_supabase:
            info = supabase_results.get(normalized)
        else:
            info = FSSAI_DATABASE.get(normalized)

        if info:
            findings.append({
                "code": normalized,
                "name": info.get("name", "Unknown"),
                "fssai_status": info.get("fssai_status", NOT_LISTED),
                "category": info.get("category", "unknown"),
                "max_limit": info.get("max_limit", "unknown"),
                "health_concern": info.get("health_concern", ""),
                "fssai_note": info.get("fssai_note", ""),
                "severity": info.get("severity", 0),
            })
        else:
            # Additive not in our FSSAI database
            findings.append({
                "code": normalized,
                "name": "Unknown",
                "fssai_status": NOT_LISTED,
                "category": "unknown",
                "max_limit": "unknown",
                "health_concern": "This additive is not in our FSSAI regulation database. It may or may not be permitted.",
                "fssai_note": "Not found in FSSAI Appendix A. Check fssai.gov.in for the latest approved list.",
                "severity": 1,
            })

    # Sort by severity (highest first)
    findings.sort(key=lambda x: x["severity"], reverse=True)
    return findings


def get_fssai_summary(findings: List[dict]) -> dict:
    """
    Generate a human-readable FSSAI summary from findings.
    """
    banned = [f for f in findings if f["fssai_status"] == BANNED]
    restricted = [f for f in findings if f["fssai_status"] == RESTRICTED]
    permitted = [f for f in findings if f["fssai_status"] == PERMITTED]
    unknown = [f for f in findings if f["fssai_status"] == NOT_LISTED]

    if banned:
        overall = "Contains BANNED additives"
        concern_level = "high"
    elif any(f["severity"] >= 3 for f in restricted):
        overall = "Contains additives with health concerns"
        concern_level = "moderate"
    elif restricted:
        overall = "Contains restricted additives (within limits)"
        concern_level = "low"
    else:
        overall = "All additives are FSSAI permitted"
        concern_level = "safe"

    return {
        "overall_status": overall,
        "concern_level": concern_level,
        "banned_count": len(banned),
        "restricted_count": len(restricted),
        "permitted_count": len(permitted),
        "unknown_count": len(unknown),
        "total_additives": len(findings),
    }

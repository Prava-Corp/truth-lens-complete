"""
Demo/Offline Mode Data
Mock product data for testing when Supabase/Open Food Facts are unavailable
"""

DEMO_PRODUCTS = {
    "8901063010116": {
        "barcode": "8901063010116",
        "product_name": "Parle-G Gold Biscuits",
        "brand": "Parle",
        "category": "Biscuits, Sweet biscuits",
        "ingredients": "Wheat Flour (Maida), Sugar, Edible Vegetable Oil (Palm Oil), Invert Syrup, Milk Solids, Leavening Agents [E500(ii), E503(ii)], Salt, Emulsifier [E322 (Soya Lecithin)], Dough Conditioner [E223], Artificial Flavour (Vanilla)",
        "additives": ["E500", "E503", "E322", "E223"],
        "flags": [
            {"flag_type": "warning", "explanation": "Contains E223 (Sodium Metabisulphite): May cause allergic reactions in sensitive individuals", "region": "India"},
            {"flag_type": "warning", "explanation": "Contains E322 (Soya Lecithin): Common allergen - soy based", "region": "EU"},
            {"flag_type": "safe", "explanation": "E500 (Sodium Bicarbonate): Generally recognized as safe", "region": "FDA"}
        ]
    },
    "8901058858242": {
        "barcode": "8901058858242",
        "product_name": "Maggi 2-Minute Noodles Masala",
        "brand": "Nestlé",
        "category": "Instant noodles, Snacks",
        "ingredients": "Wheat Flour (Maida), Palm Oil, Salt, Wheat Gluten, Mineral (Potassium Chloride), Thickener (E412), Acidity Regulators (E501, E500), Humectant (E451), Colour (E150d), Flavour Enhancer (E621, E627, E631)",
        "additives": ["E412", "E501", "E500", "E451", "E150d", "E621", "E627", "E631"],
        "flags": [
            {"flag_type": "restricted", "explanation": "Contains E621 (MSG): Restricted in some regions, may cause headaches in sensitive individuals", "region": "India"},
            {"flag_type": "warning", "explanation": "Contains E150d (Caramel Colour IV): Contains 4-MEI, a potential carcinogen", "region": "EU"},
            {"flag_type": "warning", "explanation": "Contains E451 (Triphosphate): Excessive phosphate intake linked to kidney issues", "region": "FDA"},
            {"flag_type": "banned", "explanation": "Contains E627 (Disodium Guanylate): Banned in infant food products", "region": "India"}
        ]
    },
    "8906002870059": {
        "barcode": "8906002870059",
        "product_name": "Paper Boat Aam Panna",
        "brand": "Paper Boat (Hector Beverages)",
        "category": "Beverages, Fruit drinks",
        "ingredients": "Water, Sugar, Raw Mango Pulp (15%), Black Salt, Cumin Powder, Mint Extract, Acidity Regulator (E330), Antioxidant (E300), Preservative (E211)",
        "additives": ["E330", "E300", "E211"],
        "flags": [
            {"flag_type": "warning", "explanation": "Contains E211 (Sodium Benzoate): May cause hyperactivity in children when combined with artificial colours", "region": "EU"},
            {"flag_type": "safe", "explanation": "E330 (Citric Acid): Generally recognized as safe", "region": "FDA"},
            {"flag_type": "safe", "explanation": "E300 (Ascorbic Acid/Vitamin C): Safe and beneficial", "region": "India"}
        ]
    },
    "8901725181123": {
        "barcode": "8901725181123",
        "product_name": "Britannia Good Day Cashew Cookies",
        "brand": "Britannia",
        "category": "Biscuits, Cookies",
        "ingredients": "Wheat Flour (Maida), Sugar, Edible Vegetable Oil (Palm), Cashew Nuts (6.5%), Invert Syrup, Butter (2%), Milk Solids, Leavening Agents [E500(ii), E503(ii)], Salt, Emulsifier [E322], Dough Conditioner [E223], Artificial Flavour",
        "additives": ["E500", "E503", "E322", "E223"],
        "flags": [
            {"flag_type": "warning", "explanation": "Contains E223 (Sodium Metabisulphite): May trigger asthma in sensitive individuals", "region": "India"},
            {"flag_type": "safe", "explanation": "E322 (Lecithin): Generally recognized as safe emulsifier", "region": "FDA"},
            {"flag_type": "safe", "explanation": "E500 (Sodium Bicarbonate): Safe leavening agent", "region": "EU"}
        ]
    },
    "8901491101059": {
        "barcode": "8901491101059",
        "product_name": "Coca-Cola",
        "brand": "Coca-Cola",
        "category": "Beverages, Carbonated drinks",
        "ingredients": "Carbonated Water, Sugar, Colour (E150d), Acidity Regulator (E338), Natural Flavouring (including Caffeine)",
        "additives": ["E150d", "E338"],
        "flags": [
            {"flag_type": "warning", "explanation": "Contains E150d (Caramel Colour IV): Contains 4-MEI compound, potential carcinogen at high doses", "region": "EU"},
            {"flag_type": "warning", "explanation": "Contains E338 (Phosphoric Acid): May affect calcium absorption and bone health", "region": "India"},
            {"flag_type": "warning", "explanation": "High sugar content: 10.6g per 100ml exceeds recommended limits", "region": "FDA"}
        ]
    },
    "8902080020683": {
        "barcode": "8902080020683",
        "product_name": "Lays Classic Salted Chips",
        "brand": "Lay's (PepsiCo)",
        "category": "Snacks, Potato chips",
        "ingredients": "Potato, Edible Vegetable Oil (Palmolein, Rice Bran Oil), Salt, Sugar, Dextrose (Tapioca), Milk Solids, Seasoning [Onion Powder, Acidity Regulator (E330)]",
        "additives": ["E330"],
        "flags": [
            {"flag_type": "safe", "explanation": "E330 (Citric Acid): Generally recognized as safe", "region": "India"},
            {"flag_type": "safe", "explanation": "Minimal additives - relatively clean ingredient list", "region": "EU"},
            {"flag_type": "warning", "explanation": "High sodium content: May contribute to hypertension", "region": "FDA"}
        ]
    }
}


def get_demo_product(barcode: str):
    """Get a demo product by barcode"""
    return DEMO_PRODUCTS.get(barcode)


def get_all_demo_barcodes():
    """Get all available demo barcodes"""
    return {bc: p["product_name"] for bc, p in DEMO_PRODUCTS.items()}

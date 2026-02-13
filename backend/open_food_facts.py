"""
Open Food Facts API Integration
Fetches product data from the Open Food Facts database
"""
import requests
from typing import Optional, Dict, Any

OFF_API_URL = "https://world.openfoodfacts.org/api/v2/product"


def fetch_product_from_off(barcode: str) -> Optional[Dict[str, Any]]:
    """
    Fetch product data from Open Food Facts API
    
    Args:
        barcode: Product barcode (EAN-13, UPC, etc.)
    
    Returns:
        Product data dict or None if not found
    """
    try:
        url = f"{OFF_API_URL}/{barcode}.json"
        print(f"📡 Fetching from Open Food Facts: {url}")
        
        response = requests.get(url, timeout=10)
        
        if response.status_code != 200:
            print(f"❌ OFF API returned status {response.status_code}")
            return None
        
        data = response.json()
        
        if data.get("status") != 1:
            print(f"❌ Product not found in Open Food Facts")
            return None
        
        product = data.get("product", {})
        print(f"✅ Found product: {product.get('product_name', 'Unknown')}")
        
        return product
        
    except requests.RequestException as e:
        print(f"❌ Error fetching from OFF: {e}")
        return None


def extract_additives(off_product: Dict[str, Any]) -> list:
    """
    Extract additive codes from Open Food Facts product data
    
    Args:
        off_product: Product data from OFF API
    
    Returns:
        List of additive codes (e.g., ['E322', 'E500'])
    """
    additives_tags = off_product.get("additives_tags", [])
    
    # Convert 'en:e322' format to 'E322'
    additives = []
    for tag in additives_tags:
        code = tag.split(":")[-1].upper()
        if code.startswith("E"):
            additives.append(code)
    
    return additives

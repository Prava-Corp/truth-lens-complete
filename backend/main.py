"""
Truth Lens API
FastAPI backend for the food product scanner app

Supports two modes:
- Live mode: Uses Supabase + Open Food Facts (default)
- Demo mode: Uses mock data for testing (set DEMO_MODE=true)
"""
import os
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Check if demo mode is enabled
DEMO_MODE = os.getenv("DEMO_MODE", "false").lower() == "true"

from fssai_regulations import check_product_fssai, get_fssai_summary, init_fssai_supabase

if DEMO_MODE:
    from demo_data import get_demo_product, get_all_demo_barcodes, DEMO_PRODUCTS
    print("🎮 Running in DEMO MODE (no database required)")
else:
    from product_service import fetch_and_respond
    print("🔴 Running in LIVE MODE (Supabase + Open Food Facts)")
    print("⚡ Fast mode: First scans return immediately, DB saves in background")

# Initialize FSSAI Supabase connection (falls back to local if unavailable)
init_fssai_supabase()

# Create FastAPI app
app = FastAPI(
    title="Truth Lens API",
    description="Food product health scanner for India",
    version="1.0.0"
)

# CORS Configuration - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "message": "Truth Lens API is running",
        "version": "1.0.0",
        "mode": "demo" if DEMO_MODE else "live"
    }


@app.get("/product")
def get_product(barcode: str = Query(..., min_length=5, description="Product barcode")):
    """
    Get product information by barcode

    Example barcodes to try:
    - 8901063010116 (Parle-G Biscuits)
    - 8901058858242 (Maggi Noodles)
    - 8906002870059 (Paper Boat Aam Panna)
    - 8901725181123 (Britannia Good Day)
    - 8901491101059 (Coca-Cola)
    - 8902080020683 (Lays Classic Salted)
    """
    print(f"\n📱 API Request: /product?barcode={barcode}")

    if DEMO_MODE:
        result = get_demo_product(barcode)
        if not result:
            return {"error": "Product not found", "barcode": barcode}
        # Enrich with FSSAI data
        result = _enrich_with_fssai(result)
        print(f"✅ [DEMO] Returning product: {result.get('product_name')}")
        return result

    # Live mode — fast path: returns immediately, saves to DB in background
    try:
        result = fetch_and_respond(barcode)

        if not result:
            return {"error": "Product not found", "barcode": barcode}

        # Enrich with FSSAI data
        result = _enrich_with_fssai(result)
        print(f"✅ Returning product: {result.get('product_name')}")
        return result

    except Exception as e:
        print(f"❌ Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _enrich_with_fssai(product: dict) -> dict:
    """Add FSSAI regulation data to a product response."""
    additives = product.get("additives", [])
    if additives:
        fssai_findings = check_product_fssai(additives)
        fssai_summary = get_fssai_summary(fssai_findings)
        product["fssai"] = {
            "findings": fssai_findings,
            "summary": fssai_summary,
        }
    else:
        product["fssai"] = {
            "findings": [],
            "summary": {
                "overall_status": "No additives detected",
                "concern_level": "safe",
                "banned_count": 0,
                "restricted_count": 0,
                "permitted_count": 0,
                "unknown_count": 0,
                "total_additives": 0,
            },
        }
    return product


@app.get("/barcodes")
def list_barcodes():
    """List available barcodes (demo mode) or return info"""
    if DEMO_MODE:
        return {
            "mode": "demo",
            "available_barcodes": get_all_demo_barcodes()
        }
    return {"mode": "live", "message": "Scan any barcode to look it up"}


@app.get("/health")
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "mode": "demo" if DEMO_MODE else "live",
        "database": "mock" if DEMO_MODE else "connected",
        "api": "operational"
    }


@app.get("/test", response_class=HTMLResponse)
def test_ui():
    """Built-in test UI for the API"""
    barcodes_js = ""
    if DEMO_MODE:
        items = []
        for bc, data in DEMO_PRODUCTS.items():
            items.append(f'{{barcode: "{bc}", name: "{data["product_name"]}", brand: "{data["brand"]}"}}')
        barcodes_js = ",\n            ".join(items)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Truth Lens - Test Console</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; }}
        .container {{ max-width: 800px; margin: 0 auto; padding: 20px; }}
        h1 {{ text-align: center; color: #10b981; font-size: 2em; margin: 20px 0 5px; }}
        .subtitle {{ text-align: center; color: #64748b; margin-bottom: 30px; font-size: 0.9em; }}
        .mode-badge {{ display: inline-block; background: {"#10b981" if DEMO_MODE else "#ef4444"}; color: white; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; }}
        .search-box {{ display: flex; gap: 10px; margin-bottom: 20px; }}
        input {{ flex: 1; padding: 12px 16px; background: #1e293b; border: 2px solid #334155; border-radius: 12px; color: white; font-size: 16px; outline: none; }}
        input:focus {{ border-color: #10b981; }}
        button {{ padding: 12px 24px; background: #10b981; color: white; border: none; border-radius: 12px; font-size: 16px; cursor: pointer; font-weight: 600; }}
        button:hover {{ background: #059669; }}
        .quick-scan {{ display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 25px; }}
        .quick-btn {{ padding: 8px 14px; background: #1e293b; border: 1px solid #334155; border-radius: 8px; color: #94a3b8; cursor: pointer; font-size: 13px; transition: all 0.2s; }}
        .quick-btn:hover {{ border-color: #10b981; color: #10b981; }}
        .quick-btn .brand {{ color: #64748b; font-size: 11px; }}
        .result {{ background: #1e293b; border-radius: 16px; padding: 24px; margin-top: 20px; display: none; }}
        .product-header {{ display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; }}
        .product-name {{ font-size: 1.5em; font-weight: 700; color: #f8fafc; }}
        .product-brand {{ color: #64748b; margin-top: 4px; }}
        .health-score {{ width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.8em; font-weight: 800; flex-shrink: 0; }}
        .score-good {{ background: #064e3b; color: #10b981; border: 3px solid #10b981; }}
        .score-moderate {{ background: #78350f; color: #f59e0b; border: 3px solid #f59e0b; }}
        .score-bad {{ background: #7f1d1d; color: #ef4444; border: 3px solid #ef4444; }}
        .section {{ margin-top: 20px; }}
        .section-title {{ font-size: 0.85em; color: #64748b; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; }}
        .ingredients {{ background: #0f172a; padding: 14px; border-radius: 10px; font-size: 14px; line-height: 1.6; color: #cbd5e1; }}
        .additives {{ display: flex; flex-wrap: wrap; gap: 8px; }}
        .additive {{ padding: 6px 12px; background: #0f172a; border-radius: 8px; font-size: 13px; font-weight: 600; }}
        .flags {{ display: flex; flex-direction: column; gap: 8px; }}
        .flag {{ padding: 12px 16px; border-radius: 10px; font-size: 14px; line-height: 1.5; }}
        .flag-banned {{ background: #450a0a; border-left: 4px solid #ef4444; color: #fca5a5; }}
        .flag-restricted {{ background: #431407; border-left: 4px solid #f97316; color: #fed7aa; }}
        .flag-warning {{ background: #422006; border-left: 4px solid #f59e0b; color: #fde68a; }}
        .flag-safe {{ background: #052e16; border-left: 4px solid #22c55e; color: #bbf7d0; }}
        .flag-region {{ font-size: 11px; font-weight: 700; opacity: 0.7; text-transform: uppercase; }}
        .error {{ background: #7f1d1d; color: #fca5a5; padding: 16px; border-radius: 12px; margin-top: 20px; display: none; }}
        .loading {{ text-align: center; padding: 40px; color: #64748b; display: none; }}
        .loading .spinner {{ display: inline-block; width: 30px; height: 30px; border: 3px solid #334155; border-top-color: #10b981; border-radius: 50%; animation: spin 0.8s linear infinite; }}
        @keyframes spin {{ to {{ transform: rotate(360deg); }} }}
        .barcode-display {{ font-family: monospace; color: #64748b; font-size: 13px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Truth Lens</h1>
        <p class="subtitle">Food Product Health Scanner <span class="mode-badge">{"DEMO" if DEMO_MODE else "LIVE"} MODE</span></p>

        <div class="search-box">
            <input type="text" id="barcodeInput" placeholder="Enter barcode (e.g., 8901063010116)" onkeydown="if(event.key==='Enter')scanProduct()">
            <button onclick="scanProduct()">Scan</button>
        </div>

        <div class="quick-scan" id="quickScan"></div>

        <div class="loading" id="loading">
            <div class="spinner"></div>
            <p style="margin-top:10px">Scanning product...</p>
        </div>

        <div class="error" id="error"></div>
        <div class="result" id="result"></div>
    </div>

    <script>
        const barcodes = [
            {barcodes_js}
        ];

        const quickScan = document.getElementById('quickScan');
        barcodes.forEach(b => {{
            const btn = document.createElement('div');
            btn.className = 'quick-btn';
            btn.innerHTML = b.name + ' <span class="brand">' + b.brand + '</span>';
            btn.onclick = () => {{ document.getElementById('barcodeInput').value = b.barcode; scanProduct(); }};
            quickScan.appendChild(btn);
        }});

        function calcHealthScore(additives, flags) {{
            let score = 85;
            const banned = flags.filter(f => f.flag_type === 'banned').length;
            const restricted = flags.filter(f => f.flag_type === 'restricted').length;
            const warnings = flags.filter(f => f.flag_type === 'warning').length;
            score -= banned * 30;
            score -= restricted * 15;
            score -= warnings * 8;
            score -= additives.length * 3;
            return Math.max(0, Math.min(100, score));
        }}

        async function scanProduct() {{
            const barcode = document.getElementById('barcodeInput').value.trim();
            if (!barcode) return;

            document.getElementById('loading').style.display = 'block';
            document.getElementById('result').style.display = 'none';
            document.getElementById('error').style.display = 'none';

            try {{
                const res = await fetch('/product?barcode=' + barcode);
                const data = await res.json();

                document.getElementById('loading').style.display = 'none';

                if (data.error) {{
                    document.getElementById('error').style.display = 'block';
                    document.getElementById('error').textContent = 'Product not found for barcode: ' + barcode;
                    return;
                }}

                const score = calcHealthScore(data.additives || [], data.flags || []);
                const scoreClass = score >= 70 ? 'score-good' : score >= 40 ? 'score-moderate' : 'score-bad';

                let flagsHtml = (data.flags || []).map(f =>
                    '<div class="flag flag-' + f.flag_type + '">' +
                    '<span class="flag-region">' + f.region + '</span> ' +
                    f.explanation + '</div>'
                ).join('');

                let additivesHtml = (data.additives || []).map(a =>
                    '<span class="additive">' + a + '</span>'
                ).join('');

                document.getElementById('result').innerHTML =
                    '<div class="product-header">' +
                    '  <div><div class="product-name">' + data.product_name + '</div>' +
                    '    <div class="product-brand">' + (data.brand || '') + '</div>' +
                    '    <div class="barcode-display">Barcode: ' + data.barcode + '</div></div>' +
                    '  <div class="health-score ' + scoreClass + '">' + score + '</div>' +
                    '</div>' +
                    '<div class="section"><div class="section-title">Category</div>' +
                    '<div style="color:#94a3b8">' + (data.category || 'N/A') + '</div></div>' +
                    '<div class="section"><div class="section-title">Ingredients</div>' +
                    '<div class="ingredients">' + (data.ingredients || 'Not available') + '</div></div>' +
                    '<div class="section"><div class="section-title">Additives (' + (data.additives || []).length + ')</div>' +
                    '<div class="additives">' + additivesHtml + '</div></div>' +
                    '<div class="section"><div class="section-title">Regulatory Flags</div>' +
                    '<div class="flags">' + flagsHtml + '</div></div>';

                document.getElementById('result').style.display = 'block';
            }} catch(e) {{
                document.getElementById('loading').style.display = 'none';
                document.getElementById('error').style.display = 'block';
                document.getElementById('error').textContent = 'Error: ' + e.message;
            }}
        }}
    </script>
</body>
</html>"""


# ============================================================
# RUN SERVER
# ============================================================
if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))

    mode_str = "DEMO" if DEMO_MODE else "LIVE"

    print(f"""
    ╔══════════════════════════════════════════════════════╗
    ║           🔍 TRUTH LENS API SERVER                   ║
    ╠══════════════════════════════════════════════════════╣
    ║  Mode: {mode_str}
    ║  Server: http://{host}:{port}
    ║                                                      ║
    ║  Endpoints:                                          ║
    ║  • Health:   http://localhost:{port}/
    ║  • Product:  http://localhost:{port}/product?barcode=8901063010116
    ║  • Test UI:  http://localhost:{port}/test
    ║  • Barcodes: http://localhost:{port}/barcodes
    ║                                                      ║
    ║  Press CTRL+C to stop                                ║
    ╚══════════════════════════════════════════════════════╝
    """)

    uvicorn.run("main:app", host=host, port=port, reload=True)

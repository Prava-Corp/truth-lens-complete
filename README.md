# 🔍 Truth Lens

A beautiful food product scanner app for India - Know what you're consuming!

## 📁 Project Structure

```
truth_lens_complete/
├── backend/
│   ├── main.py              # FastAPI server
│   ├── database.py          # Supabase connection
│   ├── product_service.py   # Business logic
│   ├── open_food_facts.py   # OFF API integration
│   ├── requirements.txt     # Python dependencies
│   └── .env                 # Environment variables
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── camera_scan_screen.dart
    │   │   ├── manual_scan_screen.dart
    │   │   └── product_result_screen.dart
    │   ├── services/
    │   │   └── api_service.dart
    │   ├── widgets/
    │   │   └── additive_modal.dart
    │   └── utils/
    │       └── app_theme.dart
    └── pubspec.yaml
```

---

## 🚀 STEP-BY-STEP SETUP

### Step 1: Backend Setup

```bash
# Navigate to backend folder
cd truth_lens_complete/backend

# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python main.py
```

You should see:
```
╔══════════════════════════════════════════════════════╗
║           🔍 TRUTH LENS API SERVER                   ║
║  Starting server on http://0.0.0.0:8000              ║
╚══════════════════════════════════════════════════════╝
```

### Step 2: Test the Backend

Open a new terminal and run:

```bash
# Test health endpoint
curl http://localhost:8000/

# Test product endpoint (Parle-G)
curl "http://localhost:8000/product?barcode=8901063010116"
```

Expected response:
```json
{
  "barcode": "8901063010116",
  "product_name": "Parle-G Glucose Biscuits",
  "brand": "Parle",
  "ingredients": "...",
  "additives": ["E503", "E500", "E322"],
  "flags": []
}
```

### Step 3: Flutter App Setup

```bash
# Create new Flutter project
flutter create truth_lens
cd truth_lens

# Delete the default lib folder
rm -rf lib

# Copy the flutter_app/lib folder to your project
cp -r /path/to/truth_lens_complete/flutter_app/lib .

# Copy pubspec.yaml
cp /path/to/truth_lens_complete/flutter_app/pubspec.yaml .

# Get dependencies
flutter pub get
```

### Step 4: Configure Permissions

**Android** - Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:label="Truth Lens"
        ...>
        <!-- existing content -->
    </application>
</manifest>
```

**iOS** - Edit `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Add camera permission -->
    <key>NSCameraUsageDescription</key>
    <string>Truth Lens needs camera access to scan product barcodes</string>
    
    <!-- existing content -->
</dict>
```

### Step 5: Run the App

```bash
# For Chrome (Web) - Works without camera
flutter run -d chrome

# For iOS Simulator
open -a Simulator
flutter run -d ios

# For Android Emulator
flutter run -d android

# List all devices
flutter devices
```

---

## 🧪 Test Barcodes

| Barcode | Product |
|---------|---------|
| `8901063010116` | Parle-G Biscuits |
| `8901058858242` | Maggi Noodles |
| `8906002870059` | Paper Boat Aam Panna |
| `8901725181123` | Britannia Good Day |

---

## 🔧 Troubleshooting

### "Connection refused" error

1. Make sure backend is running: `python main.py`
2. Check the API URL in `lib/services/api_service.dart`:
   - **Web/Chrome**: `http://localhost:8000`
   - **Android Emulator**: `http://10.0.2.2:8000`
   - **Physical Device**: Use your computer's IP (e.g., `http://192.168.1.100:8000`)

### "Product not found"

The product may not exist in Open Food Facts. Try the test barcodes listed above.

### Camera not working

- Camera only works on iOS/Android, not on web/desktop
- The app shows manual entry on unsupported platforms

### CORS errors

The backend already has CORS enabled for all origins. If issues persist, restart the backend.

---

## 📱 Features

- ✅ Barcode scanning (iOS/Android)
- ✅ Manual barcode entry
- ✅ Health score (0-100)
- ✅ Additive analysis
- ✅ FSSAI/EU/FDA regulatory info
- ✅ Beautiful UI with animations
- ✅ Open Food Facts integration
- ✅ Supabase data storage

---

## 🏗️ Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Flutter    │────▶│   FastAPI   │────▶│  Supabase   │
│    App      │◀────│   Backend   │◀────│  Database   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ Open Food   │
                   │   Facts     │
                   └─────────────┘
```

---

## 📄 License

MIT License - Use freely!

---

Built with ❤️ for healthier India

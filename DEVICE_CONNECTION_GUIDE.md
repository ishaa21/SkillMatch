# Physical Device Connection Troubleshooting Guide

## Current Configuration Status ✅
- **Backend Server:** Running on port 5000
- **Frontend API Config:** Configured for `192.168.0.111:5000`
- **Device:** SM M356B (RZCX930A1EF) connected via USB
- **Build Mode:** Physical device mode (not emulator)

## Quick Fixes for "Lost Connection" or "Connection Timeout"

### 1️⃣ **USB Connection Issues**

**On Your Samsung Phone:**
```
Settings → About Phone → Tap "Build Number" 7 times (if not developer)
Settings → Developer Options →
  ✅ Enable "USB Debugging"
  ✅ Enable "Stay Awake" 
  ✅ Enable "Install via USB"
  ✅ Set "USB Configuration" to "MTP" or "PTP"
```

**On Your PC:**
- Unplug and replug the USB cable
- Use a different USB port (prefer USB 3.0)
- Use original Samsung cable if possible
- Run: `adb devices` to verify connection

### 2️⃣ **Network Configuration (Critical for API Calls)**

**Verify Same Network:**
- PC and Phone MUST be on the same WiFi network
- Check your current PC IP: `ipconfig` in PowerShell
- Update `api_constants.dart` if IP changed

**Windows Firewall:**
```powershell
# Allow port 5000 in Windows Firewall
netsh advfirewall firewall add rule name="Flutter Backend" dir=in action=allow protocol=TCP localport=5000
```

**Test Backend Accessibility:**
```
From your phone's browser, visit:
http://192.168.0.111:5000/api/auth/health

Should return JSON or 404 (means backend is reachable)
```

### 3️⃣ **Gradle Build Timeout**

**First Build Issues:**
- First build can take 5-15 minutes
- Be patient, don't cancel prematurely
- Check Android Studio is not running (conflicts with adb)

**If Build Keeps Timing Out:**
```bash
# In frontend directory:
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run -d RZCX930A1EF
```

### 4️⃣ **ADB Connection Issues**

**Check ADB Status:**
```bash
# Kill and restart adb server
adb kill-server
adb start-server
adb devices
```

**Should show:**
```
List of devices attached
RZCX930A1EF    device
```

If shows "unauthorized":
- Check your phone screen for authorization dialog
- Tap "Always allow from this computer" → OK

### 5️⃣ **App Crash on Launch**

**Check Logcat:**
```bash
# Monitor real-time logs
flutter run -d RZCX930A1EF --verbose

# Or use adb logcat
adb -s RZCX930A1EF logcat | grep -i "flutter"
```

**Common Crashes:**
- **Network Permission:** Already added in AndroidManifest.xml ✅
- **HTTP Cleartext:** Already configured ✅
- **Type Errors:** Check console for Dart errors

## Running the App - Step by Step

### **Step 1: Start Backend**
```bash
cd backend
npm run dev
```
Wait for: "MongoDB Connected" and "Server running on port 5000"

### **Step 2: Verify Device Connection**
```bash
flutter devices
```
Should show: `SM M356B (mobile) • RZCX930A1EF • android-arm64`

### **Step 3: Run App**
```bash
cd frontend
flutter run -d RZCX930A1EF
```

### **Step 4: Monitor Connection**
- Keep USB cable connected
- Keep phone unlocked during first launch
- Don't unplug cable until "Flutter run" completes

## Alternative: Run on Chrome (Quick Test)

If physical device keeps disconnecting:
```bash
flutter run -d chrome
```
This runs instantly and helps verify if code works.

## IP Address Changes

**Your WiFi IP can change! When it does:**

1. **Find New IP:**
```powershell
ipconfig
# Look for "IPv4 Address" under WiFi adapter
```

2. **Update Frontend:**
```dart
// frontend/lib/core/constants/api_constants.dart
static const String _lanIP = 'YOUR_NEW_IP'; // Line 9
```

3. **Restart App:**
```bash
flutter run -d RZCX930A1EF
```

## Performance Tips

### **Hot Reload Works!**
Once app is running:
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `h` for help

### **Debug Faster:**
```bash
# Build in profile mode (faster)
flutter run --profile -d RZCX930A1EF

# Build in release mode (production speed)
flutter run --release -d RZCX930A1EF
```

## Error Messages & Solutions

| Error | Solution |
|-------|----------|
| `Lost connection to device` | Check USB cable, run `adb devices`, restart adb |
| `Gradle build timed out` | Be patient (first build), or run `flutter clean` |
| `Unable to load internships` | Backend not running or wrong IP |
| `Network error` | Check firewall, verify same WiFi, test backend URL |
| `Type error` | Check console, likely data parsing issue |

## Success Indicators ✅

**Backend Running:**
```
Server running on port 5000
MongoDB Connected: localhost
```

**App Launched:**
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Syncing files to device SM M356B...
Flutter run key commands.
```

**App Works:**
- Login page loads
- Can create account
- Can view internships
- All features responsive (our overflow fixes!)

## Quick Commands Reference

```bash
# Check Flutter doctor
flutter doctor -v

# List devices
flutter devices

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on specific device
flutter run -d RZCX930A1EF

# Run with verbose logging
flutter run -d RZCX930A1EF --verbose

# Check ADB devices
adb devices

# ADB restart
adb kill-server && adb start-server

# View phone logs
adb -s RZCX930A1EF logcat

# Backend start
cd backend && npm run dev

# Verify backend
curl http://localhost:5000/api/auth/health
```

## Need Help?

1. **Check backend console** - Look for errors
2. **Check Flutter console** - Look for red error messages  
3. **Check phone screen** - USB debugging authorization?
4. **Try Chrome** - `flutter run -d chrome` to isolate device issues
5. **Restart everything** - Phone, ADB, Flutter daemon

---

**Remember:** The overflow fixes we implemented are already in place. Once the app runs, it will be fully responsive on your Samsung device! 🎉

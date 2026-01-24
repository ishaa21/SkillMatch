# 🔧 Flutter Build Error & Login Issues - Fix Guide

## Problem Overview
You're experiencing two issues:
1. **Kotlin compilation error** - Build cache corruption
2. **Cannot log in** - Backend/Frontend connection issue

---

## ✅ Solution Steps (Execute in Order)

### Step 1: Fix Flutter Build Cache (COMPLETED ✓)

Already executed:
```bash
flutter clean
cd android
gradlew clean
flutter pub get
```

### Step 2: Delete Gradle Cache Manually

**Windows Command:**
```powershell
# Delete gradle cache
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches" -ErrorAction SilentlyContinue

# Delete Flutter build folder
cd d:\My_Data\Desktop\flutter\internship_app\frontend
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\.dart_tool -ErrorAction SilentlyContinue
```

### Step 3: Update Gradle Version (Fix Java 8 Warnings)

**File:** `frontend/android/gradle/wrapper/gradle-wrapper.properties`

Change:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
```

To:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

### Step 4: Update Android Build Configuration

**File:** `frontend/android/build.gradle`

Update to:
```gradle
buildscript {
    ext.kotlin_version = '1.9.0'  // Update this
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.0.0'  // Update this
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

**File:** `frontend/android/app/build.gradle`

Update:
```gradle
android {
    compileSdkVersion 34  // Update this
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11  // Update from 8
        targetCompatibility JavaVersion.VERSION_11  // Update from 8
    }

    kotlinOptions {
        jvmTarget = '11'  // Update from 1.8
    }

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34  // Update this
    }
}
```

---

## 🔍 Backend Login Issue

### Check 1: Is Backend Running?

```bash
cd d:\My_Data\Desktop\flutter\internship_app\backend
npm run dev
```

**Expected output:**
```
Server running in development mode on port 5000
MongoDB Connected
```

### Check 2: Is MongoDB Running?

```bash
# Check if MongoDB is running
mongod --version

# Start MongoDB (if not running)
mongod
```

### Check 3: Test Backend API Directly

**Using PowerShell:**
```powershell
# Test API health
Invoke-RestMethod -Uri "http://localhost:5000/api" -Method Get

# Test login with admin account
$body = @{
    email = "admin@skillmatch.com"
    password = "password123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Body $body -ContentType "application/json"
```

**Expected response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "admin@skillmatch.com",
    "role": "admin"
  }
}
```

### Check 4: Verify Database Has Data

```bash
cd backend
node src/scripts/verifyData.js
```

**Expected:** Shows counts of all users, students, companies

---

## 🔧 Flutter API Configuration

### Check Frontend API URL

**File:** `frontend/lib/core/constants/api_constants.dart` (or similar)

Make sure it points to:
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:5000/api';
  // OR for Android emulator:
  static const String baseUrl = 'http://10.0.2.2:5000/api';
}
```

### Android Emulator vs Physical Device

- **Android Emulator:** Use `http://10.0.2.2:5000` (localhost redirect)
- **Physical Device:** Use your computer's IP (e.g., `http://192.168.1.10:5000`)
- **Chrome/Web:** Use `http://localhost:5000`

---

## 🚀 Complete Reset & Rebuild Process

Execute these commands in order:

### 1. Clean Everything
```powershell
cd d:\My_Data\Desktop\flutter\internship_app\frontend

# Flutter clean
flutter clean

# Delete all cache
Remove-Item -Recurse -Force .\build
Remove-Item -Recurse -Force .\.dart_tool
Remove-Item -Recurse -Force .\android\.gradle
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"

# Get dependencies
flutter pub get
```

### 2. Start Backend
```powershell
cd ..\backend

# Make sure MongoDB is running first!
# mongod

# Start backend
npm run dev
```

**Wait for:** `Server running on port 5000`

### 3. Run Flutter App
```powershell
cd ..\frontend

# For web (fastest for testing)
flutter run -d chrome

# For Android
flutter run -d emulator-5554

# For physical device
flutter run
```

---

## 🐛 Common Login Errors & Fixes

### Error: "Network Error" or "Connection Refused"
**Cause:** Backend not running or wrong URL  
**Fix:** 
1. Start backend: `npm run dev`
2. Check API URL in Flutter code
3. Use `10.0.2.2` for Android emulator

### Error: "401 Unauthorized" or "Invalid credentials"
**Cause:** Wrong email/password or data not seeded  
**Fix:**
1. Re-seed database: `npm run seed:enhanced`
2. Use correct credentials:
   - Email: `admin@skillmatch.com`
   - Password: `password123`

### Error: "500 Internal Server Error"
**Cause:** Backend crash or MongoDB connection issue  
**Fix:**
1. Check backend console for errors
2. Start MongoDB: `mongod`
3. Check `.env` file has correct MONGO_URI

### Error: "User not found"
**Cause:** Database empty  
**Fix:**
```bash
cd backend
npm run seed:enhanced
```

---

## 📱 Quick Test Credentials

After seeding, try these:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@skillmatch.com | password123 |
| Student | aarav.patel@gmail.com | password123 |
| Company | hr@techmahindrasolutions.com | password123 |

---

## 🔍 Debugging Steps

### 1. Check Backend Logs
Look for errors in the backend terminal:
- MongoDB connection errors
- JWT secret issues
- Route errors

### 2. Check Flutter Console
Look for:
- API URL errors
- Network errors
- JSON parsing errors

### 3. Use Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 4. Enable Verbose Logging
**Backend:** Already has `console.log` statements  
**Flutter:** Add to login code:
```dart
print('Attempting login with: $email');
print('API Response: $response');
```

---

## 🎯 Step-by-Step Login Test

### 1. Verify Backend is Working
```powershell
# Test endpoint
curl http://localhost:5000/api

# Should return: {"message":"API is running","status":"OK"}
```

### 2. Test Login via Postman/Thunder Client
POST `http://localhost:5000/api/auth/login`
```json
{
  "email": "admin@skillmatch.com",
  "password": "password123"
}
```

### 3. If Backend Works, Check Flutter Code
**File:** Look for login function in your auth code

Should look like:
```dart
Future<void> login(String email, String password) async {
  final response = await dio.post(
    'http://10.0.2.2:5000/api/auth/login',  // Android emulator
    data: {
      'email': email,
      'password': password,
    },
  );
  
  print('Login response: $response');
  // ... handle response
}
```

---

## 🆘 Still Not Working?

### Nuclear Option: Complete Reset

```powershell
# 1. Stop all processes
# Press Ctrl+C in backend terminal

# 2. Clean Flutter completely
cd frontend
flutter clean
Remove-Item -Recurse -Force .\build
Remove-Item -Recurse -Force .\.dart_tool

# 3. Reset MongoDB
mongosh
use internship_app
db.dropDatabase()
exit

# 4. Re-seed database
cd ..\backend
npm run seed:enhanced

# 5. Start backend
npm run dev

# 6. In new terminal, run Flutter
cd ..\frontend
flutter run -d chrome
```

---

## 📋 Checklist Before Running

- [ ] MongoDB is running (`mongod`)
- [ ] Backend is running (`npm run dev` - port 5000)
- [ ] Database is seeded (`npm run seed:enhanced`)
- [ ] Flutter dependencies updated (`flutter pub get`)
- [ ] Build cache cleared (`flutter clean`)
- [ ] Correct API URL in Flutter code
- [ ] Using correct login credentials

---

## 🎉 Success Indicators

You'll know it's working when:
1. ✅ Backend shows: `Server running on port 5000`
2. ✅ Backend shows: `MongoDB Connected`
3. ✅ Flutter app builds without Kotlin errors
4. ✅ Login button works and navigates to dashboard
5. ✅ You see your name/email on the dashboard

---

**Need Help?** Check the backend terminal for error messages and share them for specific fixes.

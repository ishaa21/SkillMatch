# 🚀 Complete Startup Instructions

## Current Status
- ✅ **Flutter frontend is RUNNING** on port 61407
- ❌ **MongoDB is STOPPED** (requires admin to start)
- ❌ **Backend server is NOT RUNNING** (waiting for MongoDB)

---

## Step 1: Start MongoDB (Admin Required) ⚠️

**Open PowerShell as Administrator** and run:
```powershell
net start MongoDB
```

You should see: `The MongoDB service was started successfully.`

---

## Step 2: Start Backend Server

In a **regular PowerShell window**:
```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend
npm run dev
```

Wait for: `MongoDB Connected: localhost` and `Server running in development mode on port 5000`

---

## Step 3: Access the Flutter App

Flutter has already started and should have opened Chrome automatically.

**Look for a Chrome tab with URL like:**
```
http://127.0.0.1:61407/C8tBHs87Rgs=/
```

The `/C8tBHs87Rgs=/` part is an authentication token - you **MUST** use the full URL with this token.

**If Chrome didn't open automatically:**
- Check your Flutter terminal output for the complete URL
- Copy the full URL (with the token) and paste it into Chrome

---

## Step 4: Login

Once the app loads:
- **Company Account:** `company@test.com` / `password123`
- **Student Account:** `student@test.com` / `password123`

---

## ✅ Expected Result

You should see:
1. Beautiful login page with gradient background
2. After login: Dashboard with stats
3. Features: Create internships, view applicants, AI matching scores, etc.

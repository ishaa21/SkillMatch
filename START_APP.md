# 🚀 Start Your Internship App (After Restart)

## Step 1: Open TWO PowerShell/Terminal Windows

### Terminal 1: Start Backend
```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend
npm run dev
```

**Wait for:** `MongoDB Connected: localhost`

---

### Terminal 2: Start Frontend
```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\frontend
flutter run -d chrome
```

**Wait for:** Chrome window to open automatically

---

## Step 2: Login

**URL:** The Flutter terminal will show something like:
```
http://127.0.0.1:xxxxx
```

**Credentials:**
- **Company:** `company@test.com` / `password123`
- **Student:** `student@test.com` / `password123`

---

## ✅ What Should Work:

1. ✅ Login (2-3 seconds, no errors)
2. ✅ Dashboard with real stats
3. ✅ View/Create/Edit/Delete Internships
4. ✅ View Applicants with AI match scores
5. ✅ Update application status (Shortlist/Reject/Hire)
6. ✅ Edit Company Profile

---

## 🔴 If Still Getting Errors:

Run in PowerShell (Admin):
```powershell
Get-Service MongoDB
```

Should show: **Status: Running**

If not running:
```powershell
net start MongoDB
```

---

## 📁 Project Location:
```
c:\Users\admin\.gemini\antigravity\scratch\internship_app\
├── backend/    (Node.js + MongoDB)
└── frontend/   (Flutter + Dart)
```

---

**Enjoy your fully functional Internship App!** 🎉

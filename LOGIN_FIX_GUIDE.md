# ⚠️ LOGIN FAILED - HERE'S WHY AND HOW TO FIX

## THE PROBLEM
**MongoDB is NOT running!** Your backend server is running, but it can't connect to the database to check if `company1@test.com` exists.

---

## THE SOLUTION (3 Simple Steps)

### Step 1: Start MongoDB (MUST DO!)

**Option A - PowerShell as Administrator:**
```powershell
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe
```

**Option B - If you get an error about config file:**
```powershell
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe --dbpath "C:\data\db"
```

**If you get "data directory doesn't exist":**
```powershell
New-Item -Path "C:\data\db" -ItemType Directory -Force
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe --dbpath "C:\data\db"
```

**IMPORTANT:** You should see this at the end:
```
Waiting for connections on port 27017
```

**KEEP THAT WINDOW OPEN!** Don't close it.

---

### Step 2: Seed the Database

Open a **NEW PowerShell** window (regular, not admin) and run:

```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend
node src/utils/seedDatabase.js
```

You should see:
```
MongoDB Connected for seeding...
Clearing existing data...
Creating companies...
✓ Created 15 companies
Creating students...
✓ Created 15 students
Creating internships...
✓ Created 20 internships
Creating applications...
✓ Created 30+ applications

✅ Database seeded successfully!
=================================
Companies: 15
Students: 15
Internships: 20
Applications: 30+
=================================

Login credentials:
Company: company1@test.com / password123
Student: student1@test.com / password123
```

---

### Step 3: Try Login Again

Now go back to your Flutter app in Chrome and try:
- **Email:** `company1@test.com`
- **Password:** `password123`

**It will work now!** ✅

---

## VERIFICATION CHECKLIST

Before trying to login, make sure:
- [ ] You see "Waiting for connections on port 27017" in MongoDB window
- [ ] MongoDB window is still open (don't close it!)
- [ ] Seed script showed "✅ Database seeded successfully!"
- [ ] You're using the correct email: `company1@test.com` (NOT company@test.com)
- [ ] You're using the correct password: `password123`

---

## WHY DID LOGIN FAIL?

1. **No MongoDB running** → Backend can't access database
2. **No database data** → Even if MongoDB was running, no users exist
3. **Backend tries to find user** → Can't connect, returns error
4. **Flutter shows "Login failed"** → Because backend returned an error

Once MongoDB is running AND database is seeded, the login flow works perfectly!

---

## AFTER SUCCESSFUL LOGIN

You'll see the Company Dashboard with:
- Stats cards showing internships posted, total applications, etc.
- List of your posted internships
- Ability to create new internships
- View applicants with AI match scores
- Manage applications (Shortlist/Reject/Hire)

**All pages will be fully functional with real data!**

---

## STILL NOT WORKING?

Tell me which step failed:
1. "MongoDB won't start" → I'll help with MongoDB troubleshooting
2. "Seed script failed" → I'll help debug the connection
3. "Login still fails after seeding" → I'll check the authentication code

**Try steps 1-3 now and let me know what happens!** 🚀

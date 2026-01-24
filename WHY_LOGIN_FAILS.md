# ⚠️ WHY REGISTRATION AND LOGIN ARE BOTH FAILING

## The Problem is Simple
**MongoDB is NOT running!**

Both registration AND login need to save/read data from MongoDB:
- **Registration** → Needs to save new user to database
- **Login** → Needs to check if user exists in database

Without MongoDB running, **NOTHING will work**.

---

## ✅ THE FIX (Super Simple - 2 Steps!)

### Step 1: Start MongoDB

**Right-click** → **Run as Administrator:**
```
START_MONGODB.bat
```

You'll see a window open showing MongoDB starting. **KEEP IT OPEN!**

You should see at the end:
```
Waiting for connections on port 27017
```

### Step 2: Populate Database

**Double-click** (or run normally):
```
SEED_DATABASE.bat
```

This creates:
- 15 companies (company1@test.com to company15@test.com)
- 15 students (student1@test.com to student15@test.com)
- 20 internships
- 30+ applications

You'll see:
```
✓ Created 15 companies
✓ Created 15 students
✓ Created 20 internships
✓ Created 30+ applications
✅ Database seeded successfully!
```

---

## ✅ NOW TRY AGAIN

### Login (Recommended):
- **Email:** `company1@test.com`
- **Password:** `password123`

**OR**

- **Email:** `student1@test.com`
- **Password:** `password123`

### Registration (Optional):
If you want to test registration instead, use a NEW email like:
- **Email:** `newcompany@test.com`
- **Password:** `yourpassword`

**Both will work once MongoDB is running!**

---

## Quick Checklist

Before clicking Login/Register:
- [ ] START_MONGODB.bat is running (window is open)
- [ ] You saw "Waiting for connections on port 27017"
- [ ] SEED_DATABASE.bat completed successfully
- [ ] You see "✅ Database seeded successfully!"

---

## Why It Was Failing

1. You clicked Login → Frontend sends request to backend
2. Backend tries to check database → **MongoDB not running!**
3. Backend returns error → Frontend shows "Exception: Login failed"

Same for registration:
1. You enter details and click Sign Up → Frontend sends to backend
2. Backend tries to save to database → **MongoDB not running!**
3. Backend returns error → Frontend shows "Exception: Registration failed"

---

## After It Works

Once logged in, you'll see:
- **Company Dashboard** with all internships, applicants, AI scores
- **Student Dashboard** with available internships, applications
- **All pages working** with real data from the database

**Run those 2 batch files now and login will work!** 🎯

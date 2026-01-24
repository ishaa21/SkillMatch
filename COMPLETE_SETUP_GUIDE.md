# 🚀 Complete Setup Guide - Internship App

## Current Status
- ✅ Backend server running (port 5000)
- ✅ Flutter frontend running (check terminal for URL)
- ✅ Seed script created (15 companies, 15 students, 20 internships, 30+ applications)
- ❌ MongoDB needs to be started

---

## STEP 1: Start MongoDB (IMPORTANT!)

### Method A: Using the Batch Script (Recommended)

**Right-click** `start_mongodb.bat` → **Run as Administrator**

This script will try multiple methods to start MongoDB.

### Method B: Manual Start (If batch script fails)

Open PowerShell **AS ADMINISTRATOR** and run:

```powershell
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe --config "mongod.cfg"
```

Keep this terminal window open!

---

## STEP 2: Populate Database with Sample Data

Once MongoDB is running, open a NEW PowerShell (regular, not admin):

```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend
node src/utils/seedDatabase.js
```

You should see:
```
✓ Created 15 companies
✓ Created 15 students
✓ Created 20 internships
✓ Created 30+ applications
✅ Database seeded successfully!
```

---

## STEP 3: Access the Application

Check your Flutter terminal for a URL like:
```
http://127.0.0.1:XXXXX/AUTHENTICATION_TOKEN/
```

Copy the **FULL URL** (including the authentication token) and open it in Chrome.

---

## STEP 4: Login and Explore

Use any of these accounts:

**Companies:**
- `company1@test.com` to `company15@test.com`
- Password: `password123`

**Students:**
- `student1@test.com` to `student15@test.com`
- Password: `password123`

---

## 🎉 What You'll See

### For Companies:
- Dashboard with internship stats
- 20 internships posted by various companies
- Applications from students with AI match scores
- Manage applicants (Shortlist/Reject/Hire)

### For Students:
- Dashboard with application stats
- Browse 20 available internships
- View AI match scores for each internship
- See application status

---

## Troubleshooting

**If seed script fails:**
- Make sure MongoDB is running (check the terminal where you started it)
- Try: `Get-Service MongoDB` (should show "Running")

**If app won't load:**
- Make sure you're using the FULL URL with authentication token from Flutter terminal
- Don't use just `http://127.0.0.1:XXXXX/`

**If login fails:**
- Wait for seed script to complete successfully
- Use exact emails: company1@test.com or student1@test.com

---

## Sample Data Overview

### 15 Companies Include:
- TechCorp Solutions (Bangalore)
- InnovateLab (AI/ML, Hyderabad)
- CloudSys Inc (Mumbai)
- DataMinds Analytics (Pune)
- And 11 more...

### 20 Internships Include:
- Full Stack Developer (₹25,000/month)
- Machine Learning Intern (₹20,000/month)
- Cloud DevOps Intern (₹30,000/month)
- Mobile App Developer (₹28,000/month)
- And 16 more...

### 15 Students Include:
- From IIT Bombay, IIT Delhi, BITS Pilani, NIT Trichy
- Various skills: React, Python, Java, Flutter, ML, etc.
- Each student has applied to 2-3 internships

---

**Enjoy exploring the fully populated Internship App!** 🎊

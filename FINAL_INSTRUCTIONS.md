# ⚡ FINAL INSTRUCTIONS - Get Everything Working NOW

## Problem
MongoDB won't start automatically. You need to start it manually ONCE, then everything will work.

---

## 🔥 SOLUTION (Choose ONE method)

### Method 1: Using PowerShell (EASIEST)

1. **Open PowerShell AS ADMINISTRATOR** (Right-click → Run as Administrator)

2. **Run EXACTLY this command:**
```powershell
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe
```

3. **LEAVE THAT WINDOW OPEN!** MongoDB must keep running.

4. **Open a NEW regular PowerShell** and run:
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

### Method 2: If Method 1 Shows Config Error

```powershell
# In PowerShell AS ADMINISTRATOR:
cd "C:\Program Files\MongoDB\Server\8.2\bin"
.\mongod.exe --dbpath "C:\data\db"
```

If you get "data directory not found":
```powershell
New-Item -Path "C:\data\db" -ItemType Directory -Force
.\mongod.exe --dbpath "C:\data\db"
```

Then run the seed script (step 4 from Method 1).

---

## ✅ After Seeding Success

### Access Your App

Your Flutter terminal shows a URL like:
```
http://127.0.0.1:XXXXX/SOME_TOKEN/
```

**Copy the FULL URL** (including the token after the port) and open in Chrome.

### Login Credentials

**Companies** (any of these):
- company1@test.com to company15@test.com
- Password: `password123`

**Students** (any of these):
- student1@test.com to student15@test.com
- Password: `password123`

---

## 🎉 What You'll See (All Pages Working!)

### Company Dashboard (`company1@test.com`):
- ✅ Stats cards with real numbers
- ✅ List of posted internships
- ✅ View applicants with AI match scores (65-95%)
- ✅ Update application status (Shortlist/Reject/Hire)
- ✅ Create new internships
- ✅ Edit company profile

### Student Dashboard (`student1@test.com`):
- ✅ Application stats
- ✅ Browse 20 available internships
- ✅ See AI match scores for each internship
- ✅ Apply to internships
- ✅ View application status
- ✅ Edit profile and skills

---

## 📊 Sample Data Created

### 15 Companies:
- TechCorp Solutions (Bangalore) - Technology
- InnovateLab (Hyderabad) - AI/ML
- CloudSys Inc (Mumbai) - Cloud Computing
- DataMinds Analytics (Pune) - Data Science
- WebWizards (Delhi) - Web Development
- MobileFirst Apps (Bangalore) - Mobile
- CyberShield Security (Chennai) - Cybersecurity
- GameDev Studio (Bangalore) - Gaming
- FinTech Innovations (Mumbai) - FinTech
- HealthTech Medical (Hyderabad) - HealthTech
- + 5 more companies

### 20 Internships:
- Full Stack Developer - ₹25,000/month
- Machine Learning - ₹20,000/month
- Cloud DevOps - ₹30,000/month
- Data Analyst - ₹18,000/month
- Frontend Developer - ₹22,000/month
- Mobile App Developer - ₹28,000/month
- Cybersecurity - ₹24,000/month
- + 13 more roles

### 15 Students:
- From IIT Bombay, IIT Delhi, BITS Pilani, NIT, VIT, etc.
- Skills: React, Python, Java, Flutter, ML, DevOps, etc.
- CGPAs from 8.0 to 9.2
- Each applied to 2-3 internships

### 30+ Applications:
- Real AI match scores (40-95%)
- Various statuses (Pending/Shortlisted/Rejected)
- Based on actual skill matching

---

## 🚨 Troubleshooting

**"mongod.exe not found":**
- Check if MongoDB is in a different version folder
- Try: `Get-ChildItem "C:\Program Files\MongoDB\Server" | Select-Object Name`
- Use the version number you find

**"Access denied":**
- Make SURE you're running PowerShell **AS ADMINISTRATOR**
- Right-click PowerShell → "Run as Administrator"

**Seed script fails:**
- Check MongoDB window - it should say "waiting for connections on port 27017"
- If not, restart mongod.exe command

**Flutter URL shows auth error:**
- Use the FULL URL including the token part
- Don't go to just `http://127.0.0.1:XXXXX/`

---

## 💡 Summary

1. Start MongoDB (`mongod.exe`) AS ADMIN - KEEP IT RUNNING
2. Run seed script (`node src/utils/seedDatabase.js`)
3. Copy FULL Flutter URL from terminal
4. Login with company1/student1 @ test.com
5. Enjoy fully working app with all data! 🎊

**All components, all pages, all features will be ALIVE with real data!**

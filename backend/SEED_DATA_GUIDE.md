# 🌱 Database Seeding Guide - SkillMatch

## Overview

The enhanced seed script creates a complete, realistic dataset for testing and development.

## What Gets Created

### 📊 Data Summary
- **2 Admin Users** - Platform administrators
- **20 Companies** - 15 approved, 5 pending verification
- **20 Students** - With varying profile completion (60%-100%)
- **30 Internships** - Active internship postings from approved companies
- **50+ Applications** - With AI-generated match scores (0-100)
- **20+ Skills** - Predefined skills collection

---

## 🚀 How to Run

### Method 1: Using npm script (Recommended)

```bash
cd backend
npm run seed:enhanced
```

### Method 2: Using batch file (Windows)

```bash
cd backend
SEED_DATABASE_ENHANCED.bat
```

### Method 3: Direct Node execution

```bash
cd backend
node src/scripts/seedDataEnhanced.js
```

---

## ⚠️ Important Notes

1. **Data Loss Warning**: This script will **DELETE ALL EXISTING DATA** before seeding.
2. **MongoDB Required**: Make sure MongoDB is running on `localhost:27017`
3. **Dependencies**: Run `npm install` first if you haven't already

---

## 🔑 Default Login Credentials

All accounts use the same password: **`password123`**

### Admin Accounts
| Email | Role |
|-------|------|
| admin@skillmatch.com | Admin |
| superadmin@skillmatch.com | Super Admin |

### Company Accounts (Sample)
| Email | Company Name | Status |
|-------|--------------|--------|
| hr@techmahindrasolutions.com | TechMahindra Solutions | Approved |
| hr@innovatebangalorepvtltd.com | Innovate Bangalore Pvt Ltd | Approved |
| hr@datamindsai.com | DataMinds AI | Approved |
| hr@cloudfronttechnologies.com | CloudFront Technologies | Approved |
| hr@mobilefirstapps.com | MobileFirst Apps | Approved |
| ... (15 more) | ... | 10 more approved, 5 pending |

### Student Accounts (Sample)
| Email | Name | University | Profile % |
|-------|------|------------|-----------|
| aarav.patel@gmail.com | Aarav Patel | IIT Bombay | ~85-95% |
| diya.sharma@gmail.com | Diya Sharma | BITS Pilani | ~80-90% |
| rohan.verma@gmail.com | Rohan Verma | VIT Vellore | ~75-85% |
| ananya.singh@gmail.com | Ananya Singh | NIT Trichy | ~70-80% |
| vihaan.kumar@gmail.com | Vihaan Kumar | IIIT Hyderabad | ~85-95% |
| ... (15 more) | ... | ... | Varying |

---

## 📦 Sample Data Details

### Students
Each student has:
- ✅ Complete profile information (name, email, phone, bio)
- ✅ Profile picture (generated avatar)
- ✅ Education details (1-2 entries)
- ✅ Skills (3-7 skills with proficiency levels)
- ✅ Projects (0-3 projects)
- ✅ Certifications (0-2 certifications)
- ✅ Languages (English + Hindi)
- ✅ Location with coordinates
- ✅ Internship preferences
- ✅ Resume URL
- ✅ Social links (LinkedIn, GitHub)
- ✅ Auto-calculated profile completion %

### Companies
Each company has:
- ✅ Company profile (name, description, tagline)
- ✅ Contact information
- ✅ Location with coordinates
- ✅ Logo (generated avatar)
- ✅ Company details (type, size, industry, founded year)
- ✅ Verification status (CIN, GSTIN)
- ✅ Analytics data (internships posted, applications received)
- ✅ Approval status (15 approved, 5 pending)

### Internships
Each internship has:
- ✅ Title and description
- ✅ Required skills with proficiency levels
- ✅ Stipend range (min/max in INR)
- ✅ Work mode (Remote/On-site/Hybrid)
- ✅ Duration (3-6 months)
- ✅ Application deadline
- ✅ Location details
- ✅ Openings count
- ✅ Responsibilities and perks

### Applications
Each application includes:
- ✅ AI-generated match score (0-100)
- ✅ Match breakdown (skills, location, experience, etc.)
- ✅ Timeline tracking
- ✅ Status (Applied/Shortlisted/Interview/Hired/Rejected)
- ✅ Cover letter
- ✅ Application timestamps

---

## 🎯 Use Cases

### Testing AI Matching
- Students have diverse skill sets
- Internships require different skills
- Match scores range from 30-95%
- Test filtering by match score

### Testing Workflows
- Companies with different approval statuses
- Applications in various stages
- Timeline tracking demonstration
- Status transitions

### Testing Filters
- Location-based search (10+ cities)
- Skill-based filtering (20+ skills)
- Stipend range filtering (₹5,000 - ₹50,000)
- Work mode filtering (Remote/On-site/Hybrid)

### Testing Dashboards
- **Student Dashboard**: Browse internships, view match scores, track applications
- **Company Dashboard**: View applicants ranked by AI score, manage applications
- **Admin Dashboard**: Review pending companies, manage users, view analytics

---

## 🔧 Customization

### Modify Student Count
In `seedDataEnhanced.js`, line ~150:
```javascript
for (let i = 0; i < 20; i++) { // Change 20 to desired count
```

### Modify Company Count
Line ~100:
```javascript
for (let i = 0; i < 20; i++) { // Change 20 to desired count
```

### Modify Internship Count
Line ~450:
```javascript
for (let i = 0; i < 30; i++) { // Change 30 to desired count
```

### Modify Application Count
Line ~550:
```javascript
for (let i = 0; i < 50; i++) { // Change 50 to desired count
```

---

## 📊 Database Collections

After seeding, your MongoDB will have:

```
internship_app/
├── users (42 documents)
│   ├── 2 admins
│   ├── 20 companies
│   └── 20 students
├── students (20 documents)
├── companies (20 documents)
├── internships (30 documents)
├── applications (50+ documents)
└── skills (20+ documents)
```

---

## 🐛 Troubleshooting

### Error: "MongoDB connection failed"
**Solution**: Make sure MongoDB is running
```bash
# Start MongoDB
mongod
```

### Error: "Cannot find module"
**Solution**: Install dependencies
```bash
npm install
```

### Error: "Duplicate key error"
**Solution**: Clear database first
```javascript
// The script automatically clears data, but if needed:
use internship_app
db.dropDatabase()
```

### Script hangs or doesn't exit
**Solution**: The script should exit automatically. If not, press `Ctrl+C`

---

## 📝 Verification

After seeding, verify the data:

### Using MongoDB Compass
1. Connect to `mongodb://localhost:27017`
2. Select database: `internship_app`
3. Check collections: users, students, companies, internships, applications

### Using MongoDB Shell
```bash
mongosh
use internship_app
db.users.countDocuments()      # Should show 42
db.students.countDocuments()   # Should show 20
db.companies.countDocuments()  # Should show 20
db.internships.countDocuments() # Should show 30
db.applications.countDocuments() # Should show 50+
```

### Using API (after starting server)
```bash
# Start backend
npm run dev

# Test login
POST http://localhost:5000/api/auth/login
Body: {
  "email": "admin@skillmatch.com",
  "password": "password123"
}
```

---

## 🎨 Sample Data Features

### Realistic Indian Context
- ✅ Indian cities (Mumbai, Bangalore, Delhi, Hyderabad, etc.)
- ✅ Indian universities (IITs, NITs, BITS, etc.)
- ✅ Indian phone numbers (+91 format)
- ✅ Stipend in INR (₹5,000 - ₹50,000)
- ✅ Indian company types (Startup, SME, MNC)

### Diverse Data
- ✅ Multiple industries (IT, FinTech, EdTech, HealthTech, etc.)
- ✅ Various skill levels (Beginner to Expert)
- ✅ Different work modes (Remote, On-site, Hybrid)
- ✅ Varying profile completions (60%-100%)
- ✅ Different application statuses

### AI Match Scores
- ✅ Calculated using Jaccard Similarity algorithm
- ✅ Based on skills, location, experience, preferences
- ✅ Scores range from 30-95%
- ✅ Includes detailed breakdown

---

## 🚀 Next Steps After Seeding

1. **Start the backend server**
   ```bash
   npm run dev
   ```

2. **Test API endpoints** with Postman or similar tool

3. **Login to different accounts** to test role-based access

4. **Test the Flutter app** by running:
   ```bash
   cd ../frontend
   flutter run
   ```

5. **Explore dashboards**:
   - Admin: Approve/reject pending companies
   - Company: View AI-ranked applicants
   - Student: Browse internships, view match scores

---

## 📚 Related Documentation

- [Implementation Status](../IMPLEMENTATION_STATUS.md) - Overall project status
- [API Documentation](./API_DOCS.md) - REST API endpoints (if available)
- [Setup Guide](../COMPLETE_SETUP_GUIDE.md) - Full setup instructions

---

## 🆘 Support

If you encounter issues:
1. Check MongoDB is running
2. Verify Node.js version (14+ required)
3. Check console for error messages
4. Review the script logs

---

**Happy Testing! 🎉**

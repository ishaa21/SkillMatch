# Company Dashboard - Complete Features Guide

## Login Credentials
- **Company Account:** `company@test.com` / `password123`
- **Student Account:** `student@test.com` / `password123`

## Company Dashboard Features (Fully Functional)

### 1. **Dashboard Home** (`_buildDashboardHome()`)
**Features:**
- ✅ Company name display: "Tech Innovators Inc."
- ✅ Verification status badge (Verified/Pending)
- ✅ **Real-time Statistics Cards:**
  - Active Internships (fetched from `/api/company/stats`)
  - Total Applicants
  - Shortlisted candidates
  - Hired candidates
- ✅ Quick Actions Button: "Post New Internship"
- ✅ "View All" button navigates to Internships tab

**API Endpoints:**
- `GET /api/company/profile` - Fetches company details
- `GET /api/company/stats` - Fetches dashboard statistics

---

### 2. **My Internships** (Tab Index: 1)
**Features:**
- ✅ Lists all internships posted by the company
- ✅ Each internship card shows:
  - Title
  - Work Mode (Remote/On-site/Hybrid)
  - Stipend amount
  - Duration
  - Applicant count
- ✅ **Actions (3-dot menu):**
  - Edit Internship → Opens `CreateInternshipPage` with pre-filled data
  - View Applicants → Opens `ApplicantsPage`
  - Delete → Shows confirmation dialog, then deletes

**API Endpoints:**
- `GET /api/internships/my-internships` - Fetch company's internships
- `DELETE /api/internships/:id` - Delete internship

---

### 3. **Create/Edit Internship Page**
**Features:**
- ✅ Form fields:
  - Role Title (required)
  - Description (required, multiline)
  - Work Mode (Remote/On-site/Hybrid) - ChoiceChips
  - Location
  - Stipend (USD, required)
  - Duration (required)
  - Required Skills (FilterChips - multi-select)
- ✅ Pre-fills data when editing existing internship
- ✅ Form validation
- ✅ Loading state during save
- ✅ Success/Error feedback via SnackBar
- ✅ Returns to dashboard and reloads data on success

**API Endpoints:**
- `POST /api/internships` - Create new internship
- `PUT /api/internships/:id` - Update existing internship

---

### 4. **Applicants Management Page**
**Features:**
- ✅ Displays all applicants for a specific internship
- ✅ Each applicant card shows:
  - Student name and avatar
  - University
  - **AI Match Score** (calculated by backend)
  - Skills (up to 3 displayed as chips)
  - Current application status badge
- ✅ **Status Actions:**
  - **Shortlist** button (for Applied status)
  - **Reject** button (for Applied/Shortlisted status)
  - **Hire** button (for Shortlisted status only)
- ✅ Real-time status updates with color-coded badges
- ✅ AI-ranked applicants (sorted by match percentage)

**API Endpoints:**
- `GET /api/applications/internship/:internshipId` - Fetch applicants with AI scores
- `PUT /api/applications/:id/status` - Update application status

**AI Matching Algorithm:**
Located in `/backend/src/utils/aiMatcher.js`:
- Skills Match (40%)
- Domain/Interest Match (20%)
- Location/Work Mode (15%)
- Experience/Proficiency (15%)
- Duration/Stipend (10%)

---

### 5. **Company Profile Page**
**Features:**
- ✅ Editable company information:
  - Company Name
  - Description (multiline)
  - Industry
  - Location
  - Website
- ✅ Profile avatar/icon display
- ✅ Save Changes button
- ✅ Success/Error feedback
- ✅ Logout button in AppBar

**API Endpoints:**
- `GET /api/company/profile` - Fetch profile
- `PUT /api/company/profile` - Update profile

---

### 6. **Bottom Navigation**
All 4 tabs are functional:
1. **Dashboard** → Statistics and quick actions
2. **Internships** → List/manage internships
3. **Applicants** → View all applicants (currently placeholder)
4. **Profile** → Edit company details

---

## Backend API Summary

### Authentication
- `POST /api/auth/login` - Login (returns JWT token)
- `POST /api/auth/register` - Register new user
- `GET /api/auth/me` - Get current user

### Company Endpoints
- `GET /api/company/profile` - Get company profile
- `PUT /api/company/profile` - Update company profile
- `GET /api/company/stats` - Get dashboard statistics ⭐ NEW

### Internship Endpoints
- `GET /api/internships/my-internships` - Get company's internships
- `POST /api/internships` - Create internship
- `PUT /api/internships/:id` - Update internship
- `DELETE /api/internships/:id` - Delete internship

### Application Endpoints
- `GET /api/applications/internship/:internshipId` - Get applicants with AI match scores
- `PUT /api/applications/:id/status` - Update application status

---

## Database Collections

### Users
- email, password (hashed), role, isVerified

### Companies
- user (ref), companyName, description, industry, location, website, isApproved

### Students
- user (ref), fullName, university, degree, skills[], interests[], resumeUrl

### Internships
- company (ref), title, description, workMode, skillsRequired[], stipend{}, duration, location, deadline, isActive

### Applications
- student (ref), internship (ref), company (ref), status, appliedAt, resumeUrl, coverLetter

---

## Testing Instructions

1. **Login:** Use `company@test.com` / `password123`
2. **View Dashboard:** See stats with real data (2 internships, 2 applicants, 1 shortlisted)
3. **Navigate to Internships:** Click bottom nav or "View All"
4. **Edit Internship:** Click 3-dot menu → Edit
5. **View Applicants:** Click 3-dot menu → View Applicants
6. **Change Status:** Click Shortlist/Reject/Hire buttons
7. **Create New:** Click "+" icon or "Post New Internship"
8. **Edit Profile:** Go to Profile tab, edit fields, save

---

## Known Features Status

✅ **Fully Working:**
- Login/Authentication
- Dashboard statistics
- Create/Edit/Delete internships
- View applicants with AI matching
- Update application status
- Company profile management
- All navigation

⚠️ **Placeholder/Future:**
- Student dashboard (different user role)
- "Applicants" tab (global view - currently shows placeholder)
- Email notifications
- File upload for logos/resumes

---

## Logo Integration

The **SkillMatch logo** is integrated in:
- ✅ Login Page (replaces generic school icon)
- Path: `assets/images/skillmatch_logo.png`

To add to other pages, use:
```dart
Image.asset('assets/images/skillmatch_logo.png', height: 50)
```

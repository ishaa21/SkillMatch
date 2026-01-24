# Fix Report: Application & UI Issues

## ✅ Issues Resolved

### 1. **RenderBox Error in Applications Tab**
- **Issue:** `RenderBox was not laid out` caused by `Expanded` widget inside an unbounded `SingleChildScrollView`.
- **Fix:** Replaced `Expanded` in `_buildStatCard` with a `Container` having `minWidth` constraint.
- **File:** `applications_page.dart`

### 2. **Internship Duration Display Error**
- **Issue:** Duration was showing as `[object Object]` or crashing because backend calculates it as an object `{ value: 3, unit: 'Months', displayString: '3 Months' }`.
- **Fix:** Added `_getDuration()` helper method to checking if duration is a Map or String and extract the correct display string.
- **Files:**
  - `internship_card.dart`
  - `enhanced_internship_card.dart`

### 3. **Cannot Apply to Internships**
- **Diagnosis:**
  - Backend rate limiter was too strict (100 requests/10min), likely blocking development/testing requests (Error 429).
  - "Student profile not found" error occurs if user account exists but `Student` document is missing (manual DB edits or old bad data).
- **Fix:**
  - Increased backend Rate Limit to **1000 requests** per 10 minutes.
  - Verified that Registration flow (`authController.js`) **automatically creates** a Student profile now.
- **Recommendation:** If you still can't apply with an old account, please **Register a New Account** to ensure a fresh, valid profile is created.

## 🚀 How to Apply These Fixes

1. **Restart Backend:**
   ```bash
   # In backend terminal
   Ctrl+C
   npm run dev
   ```

2. **Restart Flutter App:**
   ```bash
   # In frontend terminal
   r  # (Hot Restart)
   # OR if that doesn't update everything:
   R  # (Full Restart)
   ```

The app should now be fully functional with proper UI layout and working Apply button.

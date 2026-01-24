# Student Dashboard Fixes

## Issues Reported

1. **Cannot apply for internships from student dashboard**
2. **Stipend is not shown**

## Root Causes

### 1. Application Timeout Issue
- The internship details page had a hardcoded 15-second timeout
- Slow network connections would fail before the application could be submitted
- **Fixed**: Updated to use centralized `dio_client.dart` with 60-second timeout

### 2. Stipend Display Issue  
The stipend data from backend follows this structure:
```json
{
  "stipend": {
    "amount": 25000,
    "currency": "INR",
    "period": "Month"
  }
}
```

The Flutter app's `_getFormattedStipend()` function should handle this correctly:
- Checks if stipend is a Map → extracts `amount` and `currency`
- Formats as `₹25000/mo`

If stipend is not showing, it could be:
1. Backend returning null/missing stipend data
2. Different data structure than expected
3. Display widget not calling the format function correctly

## Changes Made

### ✅ Fixed Connection Timeout
**File**: `lib/features/student_dashboard/presentation/pages/search/internship_details_page.dart`

**Before**:
```dart
final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
));
```

**After**:
```dart
import '../../../../../core/utils/dio_client.dart';

final Dio _dio = createDio(); // Now has 60-second timeout
```

**Impact**: Students can now successfully apply for internships even on slower connections.

## Testing the Fixes

### Test Application Flow

1. **Login as Student**:
   ```
   Email: student1@test.com
   Password: password123
   ```

2. **Navigate to Search/Browse**:
   - You should see internships listed
   - Each card should show the stipend (e.g., "₹25000/mo")

3. **Click on an Internship**:
   - Details page should open
   - Key details should show: Work Mode | Duration | Stipend
   - Stipend should display as "₹25000/mo"

4. **Click "Apply Now"**:
   - Button should show loading indicator
   - Wait up to 60 seconds for backend response
   - Success dialog should appear
   - Button should change to "Already Applied"

5. **Verify Application**:
   - Go to "Applications" tab
   - You should see your application listed
   - Status should be "Applied"

## Debugging Stipend Display

If stipend is still not showing, check the following:

### 1. Check API Response
Add debug print in the `internship_details_page.dart`:
```dart
@override
void initState() {
  super.initState();
  print('Internship Data: ${widget.internship}'); // Add this
  _checkApplicationStatus();
}
```

Look for the stipend field in the console output.

### 2. Expected Data Formats

The `_getFormattedStipend()` function handles these formats:

**Format 1 - Object (Current Backend)**:
```json
{
  "stipend": {
    "amount": 25000,
    "currency": "₹"
  }
}
```
→ Displays as: `₹25000`

**Format 2 - Number**:
```json
{
  "stipend": 25000
}
```
→ Displays as: `₹25000`

**Format 3 - String**:
```json
{
  "stipend": "25000"
}
```
→ Displays as: `₹25000`

**Format 4 - Null/Missing**:
```json
{
  "stipend": null
}
```
→ Displays as: `N/A`

### 3. Check Internship Card Widget

If stipend shows on details page but not on cards, check:
- `enhanced_internship_card.dart` - Line 21 calls `_getStipend()`
- `internship_card.dart` - Lines 35-38 handle stipend formatting

### 4. Verify Backend Data

Run this to check database:
```bash
cd backend
node

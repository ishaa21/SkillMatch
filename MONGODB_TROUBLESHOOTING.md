# MongoDB Startup Guide

## Problem: MongoDB Service Won't Start

If `net start MongoDB` gives an error, try these solutions:

### Option 1: Start MongoDB Manually (Recommended)

Open PowerShell (as Administrator) and run:

```powershell
# Find MongoDB installation
Get-WmiObject win32_service | Where-Object {$_.Name -eq 'MongoDB'} | Select-Object PathName
```

Then start MongoDB directly:
```powershell
# Common MongoDB paths (try these):
C:\Program Files\MongoDB\Server\7.0\bin\mongod.exe --config "C:\Program Files\MongoDB\Server\7.0\bin\mongod.cfg"
# OR
C:\Program Files\MongoDB\Server\6.0\bin\mongod.exe --config "C:\Program Files\MongoDB\Server\6.0\bin\mongod.cfg"
# OR
C:\Program Files\MongoDB\Server\5.0\bin\mongod.exe --config "C:\Program Files\MongoDB\Server\5.0\bin\mongod.cfg"
```

### Option 2: Fix MongoDB Service (if service exists but won't start)

```powershell
# Check service status
Get-Service MongoDB

# If service exists, try starting with sc command
sc start MongoDB

# Check for errors
Get-EventLog -LogName Application -Source MongoDB* -Newest 5
```

### Option 3: Alternative - Use Local MongoDB in Project

If MongoDB service continues to fail, we can use a local MongoDB instance:

```powershell
# In a new terminal (keep it running):
cd "C:\Program Files\MongoDB\Server\7.0\bin"
.\mongod.exe --dbpath C:\data\db
```

### Option 4: Check Common Issues

1. **Port 27017 already in use:**
   ```powershell
   netstat -ano | findstr :27017
   ```

2. **Data directory permissions:**
   - Ensure `C:\data\db` exists and has write permissions

3. **MongoDB not installed:**
   - Download from: https://www.mongodb.com/try/download/community

---

## After MongoDB Starts Successfully

Run the seed script:
```powershell
cd c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend
node src/utils/seedDatabase.js
```

Then access the app at the Flutter URL shown in your terminal.

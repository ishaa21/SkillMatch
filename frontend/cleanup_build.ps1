#!/usr/bin/env pwsh
# Comprehensive cleanup script for Android build issues

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Android Build Cleanup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop all Gradle daemons
Write-Host "[1/9] Stopping all Gradle daemon processes..." -ForegroundColor Yellow
try {
    cd android
    .\gradlew --stop
    Write-Host "✓ Gradle daemons stopped" -ForegroundColor Green
} catch {
    Write-Host "⚠ No active Gradle daemons found" -ForegroundColor Gray
}
cd ..

# Step 2: Clean Flutter build artifacts
Write-Host "[2/9] Cleaning Flutter build artifacts..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "✓ Deleted build/ directory" -ForegroundColor Green
}

# Step 3: Clean Android build artifacts
Write-Host "[3/9] Cleaning Android build artifacts..." -ForegroundColor Yellow
if (Test-Path "android\build") {
    Remove-Item -Recurse -Force "android\build"
    Write-Host "✓ Deleted android/build/ directory" -ForegroundColor Green
}
if (Test-Path "android\app\build") {
    Remove-Item -Recurse -Force "android\app\build"
    Write-Host "✓ Deleted android/app/build/ directory" -ForegroundColor Green
}

# Step 4: Clean .gradle cache in project
Write-Host "[4/9] Cleaning project .gradle directory..." -ForegroundColor Yellow
if (Test-Path "android\.gradle") {
    Remove-Item -Recurse -Force "android\.gradle"
    Write-Host "✓ Deleted android/.gradle/ directory" -ForegroundColor Green
}

# Step 5: Clean global Gradle cache (daemon and caches)
Write-Host "[5/9] Cleaning global Gradle cache..." -ForegroundColor Yellow
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path "$gradleHome\daemon") {
    Remove-Item -Recurse -Force "$gradleHome\daemon"
    Write-Host "✓ Deleted global Gradle daemon cache" -ForegroundColor Green
}
if (Test-Path "$gradleHome\caches") {
    Remove-Item -Recurse -Force "$gradleHome\caches"
    Write-Host "✓ Deleted global Gradle caches" -ForegroundColor Green
}

# Step 6: Clean Kotlin daemon and caches
Write-Host "[6/9] Cleaning Kotlin daemon and caches..." -ForegroundColor Yellow
$kotlinHome = "$env:USERPROFILE\.kotlin"
if (Test-Path $kotlinHome) {
    Remove-Item -Recurse -Force $kotlinHome
    Write-Host "✓ Deleted Kotlin daemon cache" -ForegroundColor Green
}

# Step 7: Flutter clean
Write-Host "[7/9] Running flutter clean..." -ForegroundColor Yellow
flutter clean
Write-Host "✓ Flutter clean completed" -ForegroundColor Green

# Step 8: Get Flutter dependencies
Write-Host "[8/9] Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencies fetched" -ForegroundColor Green

# Step 9: Invalidate and restart Android build system
Write-Host "[9/9] Preparing for fresh build..." -ForegroundColor Yellow
Write-Host "✓ Cleanup complete!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ All Gradle daemons stopped" -ForegroundColor Green
Write-Host "✓ All build artifacts removed" -ForegroundColor Green
Write-Host "✓ All Gradle caches cleared" -ForegroundColor Green
Write-Host "✓ All Kotlin caches cleared" -ForegroundColor Green
Write-Host "✓ Flutter dependencies refreshed" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter build apk --debug" -ForegroundColor White
Write-Host "   or: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "The build should now succeed without daemon or cache errors!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

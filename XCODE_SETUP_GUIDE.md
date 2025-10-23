# Xcode Setup Guide for Paint My Town

This guide will help you get the Paint My Town project building in Xcode and Xcode Cloud.

---

## Prerequisites

- Xcode 15.0 or later
- macOS Sonoma (14.0) or later
- Apple Developer account (for device testing and Xcode Cloud)
- Physical iOS device with iOS 16.0+ (GPS doesn't work in simulator)

---

## Step 1: Open Project in Xcode

```bash
cd /path/to/Paint-my-town
open PaintMyTown.xcodeproj
```

---

## Step 2: Add All Swift Files to the Project

We have 72 Swift files that need to be added to the Xcode project. Here's the fastest way:

### Option A: Drag and Drop (Recommended)

1. In Xcode's Project Navigator (left sidebar), select the `PaintMyTown` group
2. Open Finder and navigate to the `PaintMyTown` folder
3. Select these folders and drag them into Xcode:
   - `Coordinators/`
   - `CoreData/`
   - `Models/`
   - `Protocols/`
   - `Repositories/`
   - `Services/`
   - `Utils/`
   - `ViewModels/`
   - `Views/` (make sure to get all subfolders)

4. In the dialog that appears:
   - ✅ Check "Copy items if needed" (UNCHECK - files are already in place)
   - ✅ Check "Create groups"
   - ✅ Select the "PaintMyTown" target
   - Click "Finish"

### Option B: Add Files Manually

If drag-and-drop doesn't work:

1. Right-click on `PaintMyTown` group in Project Navigator
2. Select "Add Files to PaintMyTown..."
3. Navigate to each folder and select all `.swift` files
4. Make sure to check the "PaintMyTown" target
5. Click "Add"

Repeat for all folders listed above.

---

## Step 3: Add Info.plist

The Info.plist file has been created at `PaintMyTown/Info.plist`.

1. In Project Navigator, select `PaintMyTown` project (blue icon at top)
2. Select the `PaintMyTown` target
3. Go to "Build Settings" tab
4. Search for "Info.plist"
5. Set "Info.plist File" to: `PaintMyTown/Info.plist`

Alternatively, the project.pbxproj already references INFOPLIST_FILE but you may need to verify it points to the correct location.

---

## Step 4: Add Entitlements File

1. In Project Navigator, select `PaintMyTown` project
2. Select the `PaintMyTown` target
3. Go to "Build Settings" tab
4. Search for "Code Signing Entitlements"
5. Set value to: `PaintMyTown/PaintMyTown.entitlements`

---

## Step 5: Configure Signing & Capabilities

1. Select `PaintMyTown` target
2. Go to "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your Team from dropdown

### Add Required Capabilities:

Click the "+ Capability" button and add:

1. **Background Modes**
   - ✅ Location updates
   - ✅ Background processing

2. **HealthKit** (if not already added)
   - Should already be in entitlements file

---

## Step 6: Create Core Data Model (Visual Editor)

We have programmatic Core Data models, but Xcode prefers a visual model file:

1. File → New → File
2. Choose "Data Model" under Core Data
3. Name it: `PaintMyTown.xcdatamodeld`
4. Click "Create"

5. Follow the guide in `docs/core-data-setup-guide.md` to add entities:
   - Activity
   - LocationSample
   - Split
   - CoverageTile
   - UserSettings

**Quick Setup (Minimum for Build):**
- You can skip this initially - the code works without the visual model
- But for production, follow the complete setup guide

---

## Step 7: Configure Build Settings

### Set Deployment Target

1. Select `PaintMyTown` target
2. Go to "Build Settings"
3. Search for "iOS Deployment Target"
4. Set to: **iOS 16.0**

### Verify Swift Version

1. Search for "Swift Language Version"
2. Should be: **Swift 5**

---

## Step 8: Add Test Files

1. In Project Navigator, expand `PaintMyTownTests` group
2. Drag these test files from Finder:
   - `DependencyContainerTests.swift`
   - `LocationFilterTests.swift`
   - `LocationServiceTests.swift`
   - `LocationSmootherTests.swift`
   - `RepositoryTests.swift`
   - `SampleTests.swift`
   - `SplitCalculatorTests.swift`
   - `WorkoutPersistenceTests.swift`
   - `WorkoutServiceTests.swift`

3. Make sure to check the "PaintMyTownTests" target

---

## Step 9: Build the Project

### Clean Build Folder
1. Product → Clean Build Folder (Cmd+Shift+K)

### Build
1. Product → Build (Cmd+B)

### Fix Any Errors

Common errors and fixes:

**"Cannot find 'X' in scope"**
- Make sure the file is added to the target
- Check that the file is in the correct group

**"Duplicate symbol"**
- Check that files aren't added twice
- Clean build folder and rebuild

**Info.plist errors**
- Verify Info.plist path in Build Settings
- Make sure all permission keys are present

---

## Step 10: Run Tests

1. Product → Test (Cmd+U)
2. Expected: 90+ tests should pass

If tests fail:
- Check that test files are added to PaintMyTownTests target
- Verify Core Data stack can create in-memory store

---

## Step 11: Run on Device

**Important:** GPS tracking requires a physical device.

1. Connect your iPhone via USB
2. Select your device from the scheme menu
3. Click Run (Cmd+R)
4. On first launch:
   - Grant location permissions
   - Grant motion permissions
   - Optionally grant HealthKit permissions

---

## Step 12: Configure Xcode Cloud

### Prerequisites
- Xcode Cloud enabled in App Store Connect
- Repository connected to Xcode Cloud

### Setup Steps

1. In Xcode, go to Product → Xcode Cloud → Create Workflow
2. Select the `PaintMyTown` scheme
3. Choose branch: `claude/init-paint-my-town-app-011CUQtUdPFBQAuzTs6LiR3Y` or `main`
4. Set up workflow:
   - **Build:** On every commit
   - **Test:** Run all tests
   - **Archive:** On tag or main branch

### Xcode Cloud Environment

The project should build successfully because:
- ✅ All dependencies are native Apple frameworks (no CocoaPods/SPM)
- ✅ Info.plist is committed
- ✅ Entitlements file is committed
- ✅ Scheme is shared (`PaintMyTown.xcscheme`)
- ✅ All source files are committed

### Troubleshooting Xcode Cloud

**Build fails with "Missing files":**
- Verify all Swift files are in git: `git ls-files PaintMyTown/*.swift`
- Ensure files are added to the target in project.pbxproj

**Signing errors:**
- In Xcode Cloud settings, configure signing
- Add your Developer Team
- Set bundle identifier: `com.paintmytown.app`

**Test failures:**
- Check that test files are in target
- Review logs in Xcode Cloud dashboard

---

## Step 13: Verify Everything Works

### Checklist

- [ ] Project opens without errors
- [ ] All 72 Swift files visible in Project Navigator
- [ ] Project builds successfully (Cmd+B)
- [ ] Tests pass (Cmd+U)
- [ ] App runs on device
- [ ] Location permission request appears
- [ ] Can start a workout
- [ ] GPS tracking works
- [ ] Can save a workout

---

## Project Structure (Expected in Xcode)

```
PaintMyTown
├── PaintMyTownApp.swift
├── ContentView.swift
├── Info.plist
├── PaintMyTown.entitlements
├── Coordinators (6 files)
├── CoreData (12 files)
├── Models (13 files)
├── Protocols (4 files)
├── Repositories (5 files)
├── Services (9 files)
├── Utils (7 files)
├── ViewModels (1 file)
├── Views
│   ├── AppTabView.swift
│   ├── ErrorView.swift
│   ├── Components (4 files)
│   ├── Onboarding (2 files)
│   ├── Tabs (4 files)
│   └── Workout (1 file)
├── Assets.xcassets
└── Preview Content
    └── Preview Assets.xcassets

PaintMyTownTests
├── DependencyContainerTests.swift
├── LocationFilterTests.swift
├── LocationServiceTests.swift
├── LocationSmootherTests.swift
├── RepositoryTests.swift
├── SampleTests.swift
├── SplitCalculatorTests.swift
├── WorkoutPersistenceTests.swift
└── WorkoutServiceTests.swift
```

---

## Quick Verification Script

Run this in Terminal to verify all files exist:

```bash
cd /path/to/Paint-my-town

echo "Checking Swift files..."
find PaintMyTown -name "*.swift" | wc -l
# Should show: 72

echo "Checking test files..."
find PaintMyTownTests -name "*.swift" | wc -l
# Should show: 9

echo "Checking configuration files..."
ls -la PaintMyTown/Info.plist
ls -la PaintMyTown/PaintMyTown.entitlements

echo "All files present!"
```

---

## Common Issues and Solutions

### Issue: "File not found: Info.plist"
**Solution:**
- Verify file exists: `ls PaintMyTown/Info.plist`
- In Build Settings, set INFOPLIST_FILE to `PaintMyTown/Info.plist`

### Issue: Build succeeds but app crashes on launch
**Solution:**
- Check Console for crash logs
- Verify DependencyContainer is registering services
- Check AppState singleton initialization

### Issue: "Location permission not requested"
**Solution:**
- Verify Info.plist has NSLocationWhenInUseUsageDescription
- Check PermissionManager implementation
- Run on physical device (not simulator)

### Issue: Tests fail with Core Data errors
**Solution:**
- Verify in-memory store creation in CoreDataStack
- Check that test files use `inMemory: true`
- Clean and rebuild test target

---

## Next Steps After Successful Build

1. **Test on Device:**
   - Take a walk with the app running
   - Verify GPS tracking accuracy
   - Check battery consumption

2. **TestFlight:**
   - Archive the app (Product → Archive)
   - Upload to TestFlight
   - Invite beta testers

3. **Xcode Cloud Integration:**
   - Set up automated builds
   - Configure TestFlight distribution
   - Enable automatic testing

---

## Support

If you encounter issues:
1. Check the error log in Xcode
2. Review `docs/` folder for detailed guides
3. Verify all files are committed to git
4. Clean build folder and retry

---

**You're ready to build!** 🚀

The project should now compile and run successfully in Xcode and Xcode Cloud.

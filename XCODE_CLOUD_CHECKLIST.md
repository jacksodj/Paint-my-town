# Xcode Cloud Build Checklist

Quick checklist to ensure the project builds successfully in Xcode Cloud.

---

## ✅ Pre-Flight Checklist

### Repository Requirements
- [x] All source files committed to git
- [x] Xcode project file (.xcodeproj) committed
- [x] Shared scheme committed (`PaintMyTown.xcodeproj/xcshareddata/xcschemes/PaintMyTown.xcscheme`)
- [x] Info.plist committed
- [x] Entitlements file committed
- [x] .gitignore configured (excludes build artifacts)

### Project Configuration
- [ ] All Swift files added to Xcode target (72 files in PaintMyTown target)
- [ ] All test files added to test target (9 files in PaintMyTownTests target)
- [ ] Info.plist path configured in Build Settings
- [ ] Entitlements file configured in Build Settings
- [ ] Bundle identifier set: `com.paintmytown.app`
- [ ] Deployment target set: iOS 16.0

### Capabilities & Permissions
- [ ] Background Modes capability added (Location updates)
- [ ] HealthKit capability added (optional for initial build)
- [ ] All permission strings in Info.plist:
  - NSLocationWhenInUseUsageDescription
  - NSLocationAlwaysAndWhenInUseUsageDescription
  - NSMotionUsageDescription
  - NSHealthShareUsageDescription
  - NSHealthUpdateUsageDescription

### Dependencies
- [x] No external dependencies (all native frameworks)
- [x] No CocoaPods (no Podfile)
- [x] No Swift Package Manager dependencies (yet)
- [x] No Carthage dependencies

---

## 🔨 Local Build Verification

Before pushing to Xcode Cloud, verify locally:

```bash
# 1. Clean build
xcodebuild clean -project PaintMyTown.xcodeproj -scheme PaintMyTown

# 2. Build for iOS
xcodebuild build -project PaintMyTown.xcodeproj -scheme PaintMyTown -destination 'platform=iOS Simulator,name=iPhone 15'

# 3. Run tests
xcodebuild test -project PaintMyTown.xcodeproj -scheme PaintMyTown -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected output:
- ✅ Build succeeds
- ✅ 90+ tests pass
- ⚠️  Some location tests may fail in simulator (expected)

---

## ☁️ Xcode Cloud Configuration

### Step 1: Connect Repository

1. Open Xcode
2. Go to Product → Xcode Cloud → Create Workflow
3. Connect to your git repository
4. Select branch: `claude/init-paint-my-town-app-011CUQtUdPFBQAuzTs6LiR3Y` or `main`

### Step 2: Configure Workflow

**Build Actions:**
- ✅ Build on every commit
- ✅ Run tests
- ✅ Archive for TestFlight (optional)

**Environment:**
- Xcode Version: Latest Release (15.0+)
- macOS Version: Latest Release
- Clean build: ✅ Enabled

### Step 3: Configure Signing

In Xcode Cloud settings:
1. Add your Apple Developer Team
2. Configure signing:
   - **Automatic Signing** (recommended for development)
   - OR provide provisioning profiles

### Step 4: Start Build

1. Commit and push any changes
2. Xcode Cloud will automatically start building
3. Monitor progress in Xcode (Report Navigator → Cloud tab)

---

## 🐛 Troubleshooting Xcode Cloud Builds

### Build Error: "Command PhaseScriptExecution failed"

**Cause:** SwiftLint or other build scripts failing

**Solution:**
1. Check .swiftlint.yml exists
2. Make sure SwiftLint is available in Xcode Cloud environment
3. OR disable SwiftLint temporarily in Build Phases

### Build Error: "Missing required module"

**Cause:** Files not added to target

**Solution:**
1. Open project.pbxproj in text editor
2. Search for the missing file
3. Ensure file is in PBXBuildFile and PBXSourcesBuildPhase sections
4. Re-add file to target in Xcode

### Build Error: "No such file or directory: Info.plist"

**Cause:** Info.plist path incorrect

**Solution:**
1. Check Build Settings → INFOPLIST_FILE
2. Should be: `PaintMyTown/Info.plist`
3. Verify file exists in git: `git ls-files | grep Info.plist`

### Test Failures in Xcode Cloud

**Cause:** Tests that require device features (GPS, HealthKit)

**Solution:**
1. Skip device-specific tests in CI:
   ```swift
   #if targetEnvironment(simulator)
   throw XCTSkip("Test requires physical device")
   #endif
   ```
2. Or tag tests with `@available` checks

### Build Succeeds but Archive Fails

**Cause:** Signing configuration

**Solution:**
1. Verify provisioning profiles in Xcode Cloud
2. Check bundle identifier matches
3. Ensure certificates are valid

---

## 📊 Expected Build Times

Based on project size:
- **Clean Build:** ~3-5 minutes
- **Incremental Build:** ~1-2 minutes
- **Tests:** ~1-2 minutes
- **Total:** ~5-8 minutes

---

## ✅ Post-Build Verification

After successful Xcode Cloud build:

1. **Download Artifacts:**
   - Build logs
   - Test results
   - Archive (if configured)

2. **Review Test Results:**
   - Check test coverage report
   - Review any failed tests
   - Check performance metrics

3. **TestFlight (if configured):**
   - Verify archive uploaded
   - Check for processing errors
   - Invite testers

---

## 🚀 Optimization Tips

### Speed Up Builds

1. **Cache Dependencies:**
   - Not needed yet (no external dependencies)

2. **Parallelize Tests:**
   - Xcode Cloud does this automatically

3. **Incremental Builds:**
   - Enabled by default

### Reduce Build Failures

1. **Local Testing:**
   - Always build locally before pushing
   - Run tests before committing

2. **CI Configuration:**
   - Keep .gitignore clean
   - Commit all required files
   - Test in clean environment

---

## 📝 Current Project Status

### Committed to Git:
- ✅ 72 Swift source files
- ✅ 9 test files
- ✅ Info.plist
- ✅ Entitlements file
- ✅ .swiftlint.yml
- ✅ Xcode project structure
- ✅ Shared scheme

### Not Yet Added (Requires Xcode):
- ⚠️  Files need to be added to Xcode target
- ⚠️  Core Data visual model (optional)

### Next Actions:
1. Open project in Xcode
2. Add all files to target (follow XCODE_SETUP_GUIDE.md)
3. Build locally to verify
4. Commit project.pbxproj changes
5. Push to trigger Xcode Cloud build

---

## 📞 Support Resources

- **Xcode Cloud Documentation:** https://developer.apple.com/documentation/xcode/xcode-cloud
- **Troubleshooting Guide:** https://developer.apple.com/documentation/xcode/troubleshooting-xcode-cloud-builds
- **Build Logs:** Available in Xcode Report Navigator → Cloud tab

---

## ⚡ Quick Start

**Fastest path to Xcode Cloud build:**

```bash
# 1. Open project
open PaintMyTown.xcodeproj

# 2. In Xcode: Select all folders in PaintMyTown/, drag to project
# 3. Build locally (Cmd+B)
# 4. Commit updated project.pbxproj
git add PaintMyTown.xcodeproj/project.pbxproj
git commit -m "Add all source files to Xcode target"
git push

# 5. Set up Xcode Cloud in Xcode
# Product → Xcode Cloud → Create Workflow

# 6. Done! Builds will trigger automatically
```

---

**Status: Ready for Xcode Cloud** 🎉

All files are committed and the project structure is correct. Just need to add files to the Xcode target and push the updated project.pbxproj.

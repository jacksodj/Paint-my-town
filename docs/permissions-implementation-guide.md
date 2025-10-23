# Permissions Implementation Guide

**Phase:** M0 Phase 3 - Permissions Infrastructure
**Tasks:** M0-T18 through M0-T25
**Date:** 2025-10-23

## Overview

This document describes the complete permissions infrastructure implemented for the Paint My Town iOS app. The system handles Location, Motion, and HealthKit permissions with a clean, user-friendly interface and robust state management.

## Architecture

### Components

1. **PermissionManager** (`/PaintMyTown/Utils/PermissionManager.swift`)
   - Core permission handling logic
   - Uses Combine publishers for reactive state updates
   - Implements async/await for permission requests
   - Handles Location, Motion, and HealthKit permissions

2. **PermissionsView** (`/PaintMyTown/Views/Onboarding/PermissionsView.swift`)
   - Main onboarding screen for permissions
   - Shows permission status and request buttons
   - Beautiful gradient UI with permission cards

3. **PermissionDetailView** (`/PaintMyTown/Views/Onboarding/PermissionDetailView.swift`)
   - Detailed explanation for each permission
   - What we do / What we don't do sections
   - Privacy information
   - Permission-specific action buttons

4. **AppState Integration** (`/PaintMyTown/Models/AppState.swift`)
   - Global state management
   - Automatic permission state monitoring via Combine
   - Exposes PermissionManager through `permissions` property

5. **Info.plist Documentation** (`/docs/info-plist-configuration.md`)
   - Required Info.plist keys with descriptions
   - Configuration instructions
   - Testing guidelines

## Permission Flow

### 1. Location Permission (Required)

**Two-step authorization process:**

```swift
// Step 1: Request When In Use
let state = await permissionManager.requestLocationPermission()
// -> Shows iOS "Allow While Using App" dialog

// Step 2: Request Always (if When In Use was granted)
let state = await permissionManager.requestLocationPermission()
// -> Shows iOS "Change to Always Allow" dialog
```

**States:**
- `notDetermined` - Not yet requested
- `authorized` - When In Use or Always granted
- `denied` - User denied permission
- `restricted` - Parental controls or device restrictions

**Required Info.plist Keys:**
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

### 2. Motion Permission (Optional)

**Automatic request when querying motion data:**

```swift
let state = await permissionManager.requestMotionPermission()
// Triggers permission prompt by querying CMMotionActivityManager
```

**Use Cases:**
- Auto-pause detection during workouts
- Activity type detection (walking, running, cycling)
- Improved distance/pace accuracy

**Required Info.plist Key:**
- `NSMotionUsageDescription`

### 3. HealthKit Permission (Optional)

**Granular per-data-type authorization:**

```swift
let state = await permissionManager.requestHealthKitPermission()
// Shows HealthKit permission sheet with specific data types
```

**Data Types:**
- **Write:** Workout, WorkoutRoute
- **Read:** Workout, WorkoutRoute, HeartRate, ActiveEnergyBurned, DistanceWalkingRunning

**Required Info.plist Keys:**
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`

## Usage Examples

### Basic Permission Request

```swift
// In a view or view model
let permissionManager = PermissionManager()

Task {
    let result = await permissionManager.requestLocationPermission()

    switch result {
    case .authorized:
        print("Permission granted!")
    case .denied:
        print("Permission denied - show settings prompt")
    case .restricted:
        print("Permission restricted by device policy")
    case .notDetermined:
        print("Permission not yet determined")
    }
}
```

### Monitoring Permission State Changes

```swift
class MyViewModel: ObservableObject {
    private let permissionManager = PermissionManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Monitor location permission changes
        permissionManager.locationStatePublisher
            .sink { state in
                print("Location permission changed to: \(state)")
            }
            .store(in: &cancellables)
    }
}
```

### Using with AppState

```swift
// Access through global AppState
let appState = AppState.shared

// Check current permission status
if appState.isLocationAuthorized {
    // Start tracking workout
}

// Request permission through AppState's permission manager
Task {
    let result = await appState.permissions.requestLocationPermission()
}

// Refresh permission states when app becomes active
appState.refreshPermissionStates()
```

### Showing PermissionsView as Onboarding

```swift
struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var showPermissions = true

    var body: some View {
        if showPermissions {
            PermissionsView {
                // Called when user completes onboarding
                showPermissions = false
            }
        } else {
            MainAppView()
        }
    }
}
```

### Opening Settings for Denied Permissions

```swift
Button("Enable in Settings") {
    permissionManager.openSettings()
}
// Opens iOS Settings app to app's permission settings
```

## State Management

### Published Properties

The PermissionManager exposes permission states through:

1. **@Published properties** (for ObservableObject)
   ```swift
   @Published private(set) var locationState: PermissionState
   @Published private(set) var motionState: PermissionState
   @Published private(set) var healthKitState: PermissionState
   ```

2. **Combine publishers** (for reactive programming)
   ```swift
   var locationStatePublisher: AnyPublisher<PermissionState, Never>
   var motionStatePublisher: AnyPublisher<PermissionState, Never>
   var healthKitStatePublisher: AnyPublisher<PermissionState, Never>
   ```

### AppState Integration

AppState automatically subscribes to permission changes:

```swift
private func setupPermissionMonitoring() {
    permissionManager.locationStatePublisher
        .map { $0.isAuthorized }
        .removeDuplicates()
        .sink { [weak self] isAuthorized in
            self?.updateLocationAuthorization(authorized: isAuthorized)
        }
        .store(in: &cancellables)
}
```

This ensures the entire app is notified when permissions change (e.g., user changes settings in iOS Settings app).

## UI Components

### PermissionsView

**Features:**
- Beautiful gradient background
- Permission cards for each permission type
- Real-time status updates
- "Learn More" buttons for detailed explanations
- "Allow" buttons for requesting permissions
- "Settings" buttons for denied permissions
- Completion callback for navigation flow

**Customization:**
```swift
PermissionsView {
    // Called when permissions are complete
    navigateToMainApp()
}
```

### PermissionDetailView

**Features:**
- Large permission icon
- "What We Do" section with bullet points
- "What We Don't Do" section with bullet points
- Privacy commitment statement
- Current permission status badge
- Context-sensitive action button

**Usage:**
```swift
PermissionDetailView(
    permission: .location,
    permissionManager: permissionManager
)
```

### Permission Cards

Reusable component showing:
- Permission icon and title
- Current status (with colored indicator)
- Brief rationale text
- Action buttons (Allow/Settings)
- Status icons (checkmark/x/warning)

## Testing

### Reset Permissions (iOS Settings)

1. Settings > General > Transfer or Reset iPhone
2. Select "Reset Location & Privacy"
3. Enter passcode and confirm

Or: Uninstall and reinstall the app

### Test Scenarios

1. **Happy Path**
   - Grant all permissions
   - Verify app functionality

2. **Deny Location**
   - Deny location permission
   - Verify app shows appropriate message
   - Verify "Open Settings" button works

3. **Deny Motion**
   - Deny motion permission
   - Verify auto-pause is disabled
   - Verify app still works for tracking

4. **Deny HealthKit**
   - Deny HealthKit permission
   - Verify workouts still save locally
   - Verify no HealthKit integration

5. **Grant Later**
   - Deny permission initially
   - Grant in iOS Settings
   - Bring app to foreground
   - Verify app detects new permission state

### Debug Logging

Permission state changes are logged via the Logger utility:

```swift
logger.info("Location authorization: \(authorized)", category: .permissions)
```

Check Xcode Console for permission-related logs with category `.permissions`.

## Best Practices

### Do's

1. **Always explain why** before requesting permissions
2. **Handle all states** (notDetermined, authorized, denied, restricted)
3. **Provide fallbacks** for denied permissions
4. **Monitor state changes** to react to settings changes
5. **Use async/await** for clean permission request code
6. **Test thoroughly** on physical devices
7. **Show "Open Settings"** button for denied permissions

### Don'ts

1. **Don't request on launch** - Request in context
2. **Don't block functionality** unless permission is truly required
3. **Don't request repeatedly** - Accept user's decision
4. **Don't ignore restricted** - Handle parental controls gracefully
5. **Don't forget background modes** - Enable in Xcode capabilities
6. **Don't track without permission** - Respect user privacy

## Required Info.plist Keys

Add these keys to your Info.plist (see `/docs/info-plist-configuration.md` for details):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Paint the Town tracks your location during workouts to map where you've explored.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location allows Paint the Town to track your complete workout even when the app is closed.</string>

<key>NSMotionUsageDescription</key>
<string>Motion data helps detect when you pause during a workout for accurate tracking.</string>

<key>NSHealthShareUsageDescription</key>
<string>Read your workout history to include past activities in your coverage map.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Save your Paint the Town workouts to the Health app for a complete fitness record.</string>
```

## Background Modes

Enable in Xcode: Target > Signing & Capabilities > + Capability > Background Modes

Required modes:
- ✅ Location updates

## API Reference

### PermissionManager

#### Properties
- `locationState: PermissionState` - Current location permission state
- `motionState: PermissionState` - Current motion permission state
- `healthKitState: PermissionState` - Current HealthKit permission state

#### Methods
- `checkLocationPermission() -> PermissionState` - Check current location state
- `requestLocationPermission() async -> PermissionState` - Request location permission
- `checkMotionPermission() -> PermissionState` - Check current motion state
- `requestMotionPermission() async -> PermissionState` - Request motion permission
- `checkHealthKitPermission() -> PermissionState` - Check current HealthKit state
- `requestHealthKitPermission() async -> PermissionState` - Request HealthKit permission
- `permissionRationale(for: Permission) -> String` - Get brief rationale text
- `permissionDescription(for: Permission) -> String` - Get detailed description
- `openSettings()` - Open iOS Settings app

### PermissionState

```swift
enum PermissionState: Equatable {
    case notDetermined  // Not yet requested
    case denied         // User denied
    case authorized     // User granted
    case restricted     // Device/parental restrictions

    var isAuthorized: Bool  // true if authorized
    var canRequest: Bool    // true if notDetermined
}
```

### Permission

```swift
enum Permission: CaseIterable {
    case location
    case motion
    case healthKit

    var title: String       // Display name
    var icon: String        // SF Symbol name
}
```

## Files Created

### Core Files
1. `/PaintMyTown/Utils/PermissionManager.swift` - Permission management logic (464 lines)
2. `/PaintMyTown/Views/Onboarding/PermissionsView.swift` - Onboarding UI (267 lines)
3. `/PaintMyTown/Views/Onboarding/PermissionDetailView.swift` - Detail view (322 lines)
4. `/PaintMyTown/Models/AppState.swift` - Updated with permission monitoring

### Documentation Files
5. `/docs/info-plist-configuration.md` - Info.plist configuration guide
6. `/docs/permissions-implementation-guide.md` - This file

**Total:** 4 implementation files + 2 documentation files

## Next Steps

1. **Add Info.plist keys** in Xcode
2. **Enable Background Modes** in Xcode capabilities
3. **Test on physical device** (permissions don't work well in simulator)
4. **Integrate PermissionsView** into onboarding flow
5. **Add permission checks** before starting workouts
6. **Test state monitoring** by changing permissions in Settings

## Support

For questions or issues:
- Review the design document: `/docs/design-document.md` section 10
- Check the task plan: `/docs/project-task-plan.md` M0-T18 to M0-T25
- See Info.plist guide: `/docs/info-plist-configuration.md`

---

**Implementation Complete:** All tasks M0-T18 through M0-T25 ✅

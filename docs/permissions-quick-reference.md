# Permissions Quick Reference

Quick reference guide for working with permissions in Paint My Town.

## Quick Start

### 1. Request Location Permission

```swift
let permissionManager = PermissionManager()

Task {
    let result = await permissionManager.requestLocationPermission()
    if result.isAuthorized {
        // Start tracking
    }
}
```

### 2. Check Permission Status

```swift
let state = permissionManager.checkLocationPermission()

if state.isAuthorized {
    // Permission granted
}
```

### 3. Monitor Permission Changes

```swift
permissionManager.locationStatePublisher
    .sink { state in
        // React to changes
    }
    .store(in: &cancellables)
```

### 4. Open Settings for Denied Permissions

```swift
permissionManager.openSettings()
```

## Permission States

| State | Description | User Action Needed |
|-------|-------------|-------------------|
| `notDetermined` | Not yet requested | Request permission |
| `authorized` | Permission granted | None |
| `denied` | User denied | Open Settings |
| `restricted` | Device restrictions | Contact admin/parent |

## Permission Types

| Permission | Required | Purpose |
|-----------|----------|---------|
| Location | ✅ Yes | Track workout routes |
| Motion | ❌ No | Auto-pause detection |
| HealthKit | ❌ No | Save to Health app |

## Using with AppState

```swift
// Global access
let appState = AppState.shared

// Check status
if appState.isLocationAuthorized { }

// Request permission
let result = await appState.permissions.requestLocationPermission()

// Refresh states
appState.refreshPermissionStates()
```

## UI Components

### Show Onboarding

```swift
PermissionsView {
    // Called when complete
}
```

### Show Detail

```swift
PermissionDetailView(
    permission: .location,
    permissionManager: permissionManager
)
```

## Info.plist Keys (Required)

```xml
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSMotionUsageDescription
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription
```

See `/docs/info-plist-configuration.md` for full descriptions.

## Common Patterns

### Before Starting Workout

```swift
guard appState.isLocationAuthorized else {
    // Show permission prompt
    return
}
// Start workout
```

### Handle Denied Permission

```swift
if state == .denied {
    // Show alert with "Open Settings" button
    showSettingsAlert()
}
```

### Observing All Permissions

```swift
Publishers.CombineLatest3(
    permissionManager.locationStatePublisher,
    permissionManager.motionStatePublisher,
    permissionManager.healthKitStatePublisher
)
.sink { location, motion, healthKit in
    // Handle changes
}
.store(in: &cancellables)
```

## Testing

### Reset Permissions
- Settings > General > Transfer or Reset iPhone
- Select "Reset Location & Privacy"

### Test States
1. ✅ All granted
2. ❌ Location denied
3. ⚠️ Motion restricted
4. 🔄 Grant in Settings

## Common Issues

### Issue: Permission request not showing

**Solution:** Ensure Info.plist keys are added

### Issue: Always permission not requested

**Solution:** Request When In Use first, then Always

### Issue: State not updating

**Solution:** Call `refreshPermissionStates()` when app becomes active

### Issue: Simulator not working

**Solution:** Test on physical device (permissions limited in simulator)

## Files Location

- **PermissionManager:** `/PaintMyTown/Utils/PermissionManager.swift`
- **PermissionsView:** `/PaintMyTown/Views/Onboarding/PermissionsView.swift`
- **PermissionDetailView:** `/PaintMyTown/Views/Onboarding/PermissionDetailView.swift`
- **AppState:** `/PaintMyTown/Models/AppState.swift`

## Full Guide

See `/docs/permissions-implementation-guide.md` for complete documentation.

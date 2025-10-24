# Background Location Setup Guide

This document describes the setup requirements for background location tracking in Paint My Town.

## Overview

Paint My Town requires background location access to track workouts even when the app is not in the foreground. This allows users to:
- Lock their device during workouts
- Switch to other apps (music, maps, etc.)
- Receive calls without losing tracking data
- Continue recording their route automatically

## Required Capabilities

### 1. Background Modes Capability

The app requires the **Location updates** background mode to be enabled.

**Xcode Setup:**
1. Open the Paint My Town project in Xcode
2. Select the **PaintMyTown** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** and add **Background Modes**
5. Check **Location updates**

**Result:** This adds the following to `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### 2. Info.plist Permission Strings

The following permission descriptions must be present in `Info.plist`:

```xml
<!-- Required for basic location tracking -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Paint the Town tracks your location during workouts to map where you've explored.</string>

<!-- Required for background location tracking -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location allows Paint the Town to track your complete workout even when the app is closed or you're using other apps.</string>

<!-- Optional but recommended for motion detection -->
<key>NSMotionUsageDescription</key>
<string>Motion data helps detect when you pause during a workout for accurate tracking.</string>
```

### 3. CLLocationManager Configuration

The LocationService is configured for background updates:

```swift
manager.allowsBackgroundLocationUpdates = true
manager.pausesLocationUpdatesAutomatically = false
manager.showsBackgroundLocationIndicator = true
manager.activityType = .fitness  // or .otherNavigation for biking
```

## Authorization Flow

### Step 1: Request When-In-Use Authorization

First time users will be prompted for "When In Use" permission:

```swift
manager.requestWhenInUseAuthorization()
```

### Step 2: Request Always Authorization

For background tracking, upgrade to "Always" authorization:

```swift
manager.requestAlwaysAuthorization()
```

**Important:** You must have When-In-Use authorization before requesting Always authorization.

### Step 3: Handle Authorization Changes

Monitor authorization changes:

```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    // Handle status: .authorizedAlways, .authorizedWhenInUse, .denied, etc.
}
```

## Best Practices

### 1. Battery Optimization

Configure tracking based on activity type:

- **Walking:** Best accuracy, 5m distance filter
- **Running:** Best accuracy, 5m distance filter
- **Biking:** Best for navigation accuracy, 10m distance filter

Use `BatteryOptimizationLevel`:
- **Performance:** Best accuracy, highest battery usage
- **Balanced:** Good accuracy, moderate battery usage
- **Battery Saver:** Lower accuracy, best battery life

### 2. User Communication

**Permission Rationale:**
```
"Paint the Town needs background location to track your complete workout, even when:
- Your phone is locked
- You're using other apps
- You receive calls or notifications

Your location data is stored locally and never shared without your consent."
```

**Settings Deeplink:**
If permission is denied, guide users to Settings:
```swift
permissionManager.openSettings()
```

### 3. Minimize Background Activity

- **Stop updates when not tracking:** Call `stopTracking()` to conserve battery
- **Pause updates during breaks:** Use `pauseTracking()` instead of stopping
- **Use distance filter:** Avoid unnecessary updates when stationary

### 4. Handle Edge Cases

**App Termination:**
- iOS may terminate the app in low memory situations
- Implement state restoration to resume tracking if needed
- Persist workout data frequently

**Location Services Disabled:**
```swift
guard CLLocationManager.locationServicesEnabled() else {
    throw LocationError.locationServicesDisabled
}
```

**Reduced Accuracy:**
- iOS 14+ allows users to grant approximate location
- Check and handle reduced accuracy gracefully

## Testing Background Location

### 1. Xcode Simulator Testing

**Simulate Location:**
1. Debug > Simulate Location
2. Choose from preset routes (City Run, City Bicycle Ride, etc.)
3. Or use GPX files for custom routes

**Debug Background:**
1. Run the app
2. Start tracking
3. Press Home button (Cmd+Shift+H)
4. Location updates should continue

### 2. Device Testing

**Real Device:**
1. Build and run on a physical device
2. Start a workout
3. Lock the device or switch apps
4. Check that location updates continue
5. Verify the blue background indicator appears

**Battery Testing:**
1. Test with different battery optimization levels
2. Monitor battery usage in Settings > Battery
3. Compare battery drain across activity types

### 3. Logs and Debugging

Enable location logging:
```swift
Logger.shared.info("Location update: \(location)", category: .location)
```

Check logs:
- Console.app on macOS
- Device logs in Xcode (Window > Devices and Simulators)

## Troubleshooting

### Background Updates Not Working

**Check:**
1. ✅ Background Modes capability enabled
2. ✅ Location updates mode selected
3. ✅ `allowsBackgroundLocationUpdates = true`
4. ✅ Always authorization granted
5. ✅ Info.plist permission strings present

### Battery Drain Issues

**Solutions:**
1. Increase `distanceFilter` value
2. Use `batteryOptimization: .balanced` or `.batterySaver`
3. Implement auto-pause to stop updates when stationary
4. Reduce desired accuracy during pauses

### Permission Denied

**User Education:**
- Explain why background access is needed
- Show in-app permission rationale before requesting
- Provide Settings deeplink for denied permissions

## App Store Requirements

### Privacy Policy

Must include information about:
- What location data is collected
- How it's used (workout tracking, coverage mapping)
- How it's stored (locally on device)
- Whether it's shared (no third-party sharing by default)

### App Review Guidelines

Be prepared to explain:
- Why your app needs background location
- How users benefit from continuous tracking
- What battery optimizations are implemented
- How users can disable background tracking

### Privacy Manifest

iOS 17+ requires privacy manifests for certain data types. Include location data reasons:
```
NSLocationWhenInUseUsageDescription - Workout tracking
NSLocationAlwaysAndWhenInUseUsageDescription - Continuous workout tracking
```

## Code Examples

### Starting Background Tracking

```swift
// Request always authorization first
let permissionState = await locationService.requestAlwaysAuthorization()

guard permissionState.isAuthorized else {
    // Show permission denied UI
    return
}

// Start tracking with background config
let config = LocationTrackingConfig.standard(for: .run)
try await locationService.startTracking(config: config)
```

### Handling App Background

```swift
// In AppDelegate or SceneDelegate
func sceneDidEnterBackground(_ scene: UIScene) {
    // Ensure location updates continue
    if workoutService.activeWorkout != nil {
        // Tracking continues automatically
        Logger.shared.info("App backgrounded during active workout", category: .location)
    }
}
```

### Battery-Aware Configuration

```swift
// Check battery level and adjust
let batteryLevel = UIDevice.current.batteryLevel

let optimization: BatteryOptimizationLevel
if batteryLevel < 0.2 {
    optimization = .batterySaver
} else if batteryLevel < 0.5 {
    optimization = .balanced
} else {
    optimization = .performance
}

var config = LocationTrackingConfig.standard(for: activityType)
config.batteryOptimization = optimization
locationService.updateConfiguration(config)
```

## Resources

- [Apple Documentation: Getting the User's Location](https://developer.apple.com/documentation/corelocation/getting_the_user_s_location)
- [Apple Documentation: Handling Location Updates in the Background](https://developer.apple.com/documentation/corelocation/handling_location_updates_in_the_background)
- [WWDC: What's New in Location](https://developer.apple.com/videos/play/wwdc2020/10660/)
- [Human Interface Guidelines: Accessing Private Data](https://developer.apple.com/design/human-interface-guidelines/privacy)

---

**Last Updated:** 2025-10-23
**Version:** 1.0
**Milestone:** M1 - Phase 1 (Location Service)

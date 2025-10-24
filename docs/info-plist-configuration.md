# Info.plist Configuration for Paint My Town

This document describes the required Info.plist keys for the Paint My Town iOS app. These keys must be added to the Info.plist file to enable location tracking, motion detection, and HealthKit integration.

## Required Info.plist Keys

### Location Permissions

#### NSLocationWhenInUseUsageDescription
**Key:** `NSLocationWhenInUseUsageDescription`
**Type:** String
**Required:** Yes
**Description:**
```
Paint the Town tracks your location during workouts to map where you've explored.
```
**Purpose:** This permission is requested first and allows the app to track location while it is in use. This is a prerequisite for requesting Always authorization.

#### NSLocationAlwaysAndWhenInUseUsageDescription
**Key:** `NSLocationAlwaysAndWhenInUseUsageDescription`
**Type:** String
**Required:** Yes
**Description:**
```
Background location allows Paint the Town to track your complete workout even when the app is closed.
```
**Purpose:** Enables background location tracking so workouts can continue recording when the app is in the background or the screen is locked. Essential for uninterrupted workout tracking.

### Motion Permissions

#### NSMotionUsageDescription
**Key:** `NSMotionUsageDescription`
**Type:** String
**Required:** Yes
**Description:**
```
Motion data helps detect when you pause during a workout for accurate tracking.
```
**Purpose:** Allows access to motion and fitness data via Core Motion (CMMotionActivityManager). Used to detect when the user has stopped moving to enable auto-pause functionality.

### HealthKit Permissions

#### NSHealthShareUsageDescription
**Key:** `NSHealthShareUsageDescription`
**Type:** String
**Required:** Yes
**Description:**
```
Read your workout history to include past activities in your coverage map.
```
**Purpose:** Allows the app to read workout data from HealthKit. This enables importing past workouts from other fitness apps to include in coverage maps.

#### NSHealthUpdateUsageDescription
**Key:** `NSHealthUpdateUsageDescription`
**Type:** String
**Required:** Yes
**Description:**
```
Save your Paint the Town workouts to the Health app for a complete fitness record.
```
**Purpose:** Allows the app to write workout data to HealthKit. This ensures workouts are saved to the user's central Health database and synchronized across devices.

## Background Modes Configuration

In addition to Info.plist keys, the following background modes must be enabled in the app's capabilities:

### Required Background Modes
- **Location updates:** For continuous GPS tracking during workouts
- **Background fetch:** For periodic data synchronization (optional)
- **Audio, AirPlay, and Picture in Picture:** If audio cues are implemented (optional)

### Xcode Configuration Steps

1. Select the project in Xcode
2. Select the target (PaintMyTown)
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" button
5. Add "Background Modes"
6. Check "Location updates"

## Privacy Policy Compliance

When using these permissions, the app must:
1. Clearly explain why each permission is needed before requesting it
2. Provide value even if optional permissions are denied
3. Allow users to manage permission settings
4. Include a privacy policy that details data collection and usage
5. Never track location without user consent
6. Store data locally by default (CloudKit sync is optional)

## Implementation Notes

- Location permissions follow a two-step flow: first "When In Use", then "Always"
- Users can change permissions at any time in iOS Settings
- The app should handle all permission states gracefully:
  - Not Determined (first launch)
  - Denied (user rejected)
  - Authorized (user granted)
  - Restricted (parental controls or enterprise restrictions)
- HealthKit permissions are granular and per-data-type
- Motion permission is requested when starting first workout

## Testing Permission Flows

### Reset Permissions for Testing
1. Go to Settings > General > Transfer or Reset iPhone
2. Select "Reset Location & Privacy"
3. Enter passcode
4. Confirm reset

Alternatively, uninstall and reinstall the app.

### Test Different Permission States
- Grant all permissions (happy path)
- Deny location (app should show limited functionality)
- Deny motion (auto-pause should be disabled)
- Deny HealthKit (workout recording should still work)
- Grant permissions later via Settings (app should detect and update)

## Reference

See the following files for implementation:
- `/PaintMyTown/Services/PermissionManager.swift` - Permission handling logic
- `/PaintMyTown/Views/Onboarding/PermissionsView.swift` - Permission UI
- `/PaintMyTown/Views/Onboarding/PermissionDetailView.swift` - Permission explanations

## Apple Documentation

- [Requesting Authorization for Location Services](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)
- [Setting Up HealthKit](https://developer.apple.com/documentation/healthkit/setting_up_healthkit)
- [Core Motion Documentation](https://developer.apple.com/documentation/coremotion)

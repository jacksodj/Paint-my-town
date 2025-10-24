# Core Data Setup Guide

## Overview

This guide explains how to set up the Core Data model file (.xcdatamodeld) in Xcode. The programmatic implementation is already complete, but Xcode requires a visual model file for proper integration.

## What's Already Done

The following files have been created and are production-ready:

### Domain Models (Pure Swift)
- `/PaintMyTown/Models/Activity.swift`
- `/PaintMyTown/Models/LocationSample.swift`
- `/PaintMyTown/Models/Split.swift`
- `/PaintMyTown/Models/CoverageTile.swift`
- `/PaintMyTown/Models/UserSettings.swift`
- `/PaintMyTown/Models/ActivityType.swift`
- `/PaintMyTown/Models/DistanceUnit.swift`

### Core Data Entities
- `/PaintMyTown/CoreData/ActivityEntity+CoreDataClass.swift`
- `/PaintMyTown/CoreData/ActivityEntity+CoreDataProperties.swift`
- `/PaintMyTown/CoreData/LocationSampleEntity+CoreDataClass.swift`
- `/PaintMyTown/CoreData/LocationSampleEntity+CoreDataProperties.swift`
- `/PaintMyTown/CoreData/SplitEntity+CoreDataClass.swift`
- `/PaintMyTown/CoreData/SplitEntity+CoreDataProperties.swift`
- `/PaintMyTown/CoreData/CoverageTileEntity+CoreDataClass.swift`
- `/PaintMyTown/CoreData/CoverageTileEntity+CoreDataProperties.swift`
- `/PaintMyTown/CoreData/UserSettingsEntity+CoreDataClass.swift`
- `/PaintMyTown/CoreData/UserSettingsEntity+CoreDataProperties.swift`

### Core Data Infrastructure
- `/PaintMyTown/CoreData/CoreDataModel.swift` - Programmatic model definition
- `/PaintMyTown/CoreData/ActivityEntity+Mapper.swift` - Entity ↔ Domain mappers
- `/PaintMyTown/Repositories/CoreDataStack.swift` - Stack management

### Repositories
- `/PaintMyTown/Repositories/ActivityRepositoryProtocol.swift`
- `/PaintMyTown/Repositories/ActivityRepository.swift`
- `/PaintMyTown/Repositories/CoverageTileRepositoryProtocol.swift`
- `/PaintMyTown/Repositories/CoverageTileRepository.swift`

### Tests
- `/PaintMyTownTests/RepositoryTests.swift` - Comprehensive test suite

## What Needs to Be Done in Xcode

### Step 1: Create the .xcdatamodeld File

1. Open the project in Xcode
2. Right-click on the `PaintMyTown` group
3. Select **New File... > Core Data > Data Model**
4. Name it: `PaintMyTown.xcdatamodeld`
5. Save it in the `PaintMyTown` directory

### Step 2: Add ActivityEntity

1. Click the "+" button at the bottom to add a new entity
2. Name it: `ActivityEntity`
3. Set the class name to `ActivityEntity` (not `Activity`)
4. Set the module to `PaintMyTown`
5. Set codegen to **Manual/None** (we already have the classes)

**Add Attributes:**
- `id` - UUID - Not Optional
- `type` - String - Not Optional - Add Index
- `startDate` - Date - Not Optional - Add Index
- `endDate` - Date - Not Optional
- `distance` - Double - Not Optional
- `duration` - Double - Not Optional
- `elevationGain` - Double - Not Optional
- `elevationLoss` - Double - Not Optional
- `averagePace` - Double - Not Optional
- `notes` - String - Optional

**Add Relationships:**
- `locations` - To-Many - Destination: LocationSampleEntity - Delete Rule: Cascade
- `splits` - To-Many - Destination: SplitEntity - Delete Rule: Cascade

### Step 3: Add LocationSampleEntity

1. Add new entity: `LocationSampleEntity`
2. Set codegen to **Manual/None**

**Add Attributes:**
- `id` - UUID - Not Optional
- `latitude` - Double - Not Optional
- `longitude` - Double - Not Optional
- `altitude` - Double - Not Optional
- `horizontalAccuracy` - Double - Not Optional
- `verticalAccuracy` - Double - Not Optional
- `timestamp` - Date - Not Optional
- `speed` - Double - Not Optional

**Add Relationships:**
- `activity` - To-One - Destination: ActivityEntity - Delete Rule: Nullify - Inverse: locations

### Step 4: Add SplitEntity

1. Add new entity: `SplitEntity`
2. Set codegen to **Manual/None**

**Add Attributes:**
- `id` - UUID - Not Optional
- `distance` - Double - Not Optional
- `duration` - Double - Not Optional
- `pace` - Double - Not Optional
- `elevationGain` - Double - Not Optional

**Add Relationships:**
- `activity` - To-One - Destination: ActivityEntity - Delete Rule: Nullify - Inverse: splits

### Step 5: Add CoverageTileEntity

1. Add new entity: `CoverageTileEntity`
2. Set codegen to **Manual/None**

**Add Attributes:**
- `geohash` - String - Not Optional - Add Index
- `latitude` - Double - Not Optional
- `longitude` - Double - Not Optional
- `visitCount` - Integer 32 - Not Optional
- `firstVisited` - Date - Not Optional
- `lastVisited` - Date - Not Optional

### Step 6: Add UserSettingsEntity

1. Add new entity: `UserSettingsEntity`
2. Set codegen to **Manual/None**

**Add Attributes:**
- `id` - UUID - Not Optional
- `distanceUnit` - String - Not Optional
- `mapType` - String - Not Optional
- `coverageAlgorithm` - String - Not Optional
- `autoStartWorkout` - Boolean - Not Optional
- `autoPauseEnabled` - Boolean - Not Optional
- `healthKitEnabled` - Boolean - Not Optional
- `defaultActivityType` - String - Not Optional

### Step 7: Configure Indexes

For optimal query performance:

1. Select `ActivityEntity`
2. In the Data Model Inspector, add a compound index:
   - Properties: `startDate`, `type`

3. Select `CoverageTileEntity`
4. Ensure `geohash` is indexed (should already be set)

### Step 8: Add All Files to Target

Make sure all the created Swift files are added to both the app target and test target:

1. Select each file in the Project Navigator
2. In the File Inspector (right panel), check:
   - ✅ PaintMyTown (app target)
   - ✅ PaintMyTownTests (test target)

## Verification Steps

### 1. Build the Project

```bash
# In Xcode, press Cmd+B or Product > Build
```

There should be no compilation errors.

### 2. Run the Tests

```bash
# In Xcode, press Cmd+U or Product > Test
```

All tests in `RepositoryTests.swift` should pass:
- ✅ testCreateActivity
- ✅ testFetchAllActivities
- ✅ testFetchActivityById
- ✅ testFetchActivityByIdNotFound
- ✅ testFetchActivitiesWithDateRangeFilter
- ✅ testFetchActivitiesWithTypeFilter
- ✅ testFetchActivitiesWithDistanceFilter
- ✅ testUpdateActivity
- ✅ testDeleteActivity
- ✅ testDeleteAllActivities
- ✅ testActivityWithLocationsAndSplits
- ✅ testUpsertNewTile
- ✅ testUpsertExistingTile
- ✅ testFetchTilesByGeohash
- ✅ testFetchTilesByRegion
- ✅ testDeleteAllTiles

### 3. Test Core Data Stack

Add this temporary code to test the stack:

```swift
// In PaintMyTownApp.swift or a test view
let stack = CoreDataStack.shared
let repository = ActivityRepository(coreDataStack: stack)

Task {
    let testActivity = Activity(
        type: .run,
        startDate: Date(),
        endDate: Date().addingTimeInterval(1800),
        distance: 5000,
        duration: 1800,
        elevationGain: 50,
        elevationLoss: 45,
        averagePace: 360
    )

    do {
        let saved = try await repository.create(activity: testActivity)
        print("✅ Activity saved: \(saved.id)")

        let fetched = try await repository.fetchAll()
        print("✅ Fetched \(fetched.count) activities")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (ViewModels consume repositories)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Repository Layer                │
│  ActivityRepository                     │
│  CoverageTileRepository                 │
│  (Protocol-based, testable)             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Core Data Layer                 │
│  CoreDataStack                          │
│  Entity Mappers (Entity ↔ Domain)       │
│  NSManagedObject subclasses             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Domain Layer                    │
│  Pure Swift models                      │
│  Activity, LocationSample, etc.         │
│  (No Core Data dependencies)            │
└─────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Clean Architecture
- Domain models are pure Swift (no Core Data dependencies)
- Repositories provide abstraction over Core Data
- Easy to test with in-memory stores
- Can swap persistence layer if needed

### 2. Async/Await
- All repository methods use async/await
- Better concurrency handling
- Cleaner code than completion handlers

### 3. Background Context
- Write operations use background contexts
- UI remains responsive during saves
- Proper context merging

### 4. Type Safety
- Enums for types (ActivityType, DistanceUnit, etc.)
- Compile-time safety for configurations

### 5. Error Handling
- Custom CoreDataError enum
- Descriptive error messages
- Proper error propagation

## Next Steps

After completing the Xcode setup:

1. ✅ Verify all tests pass
2. ✅ Test create/read/update/delete operations
3. Move to **Milestone M0 Phase 3**: Permissions Infrastructure
4. Then **Milestone M1**: Recording Engine (GPS tracking)

## Troubleshooting

### Problem: "No NSEntityDescription for class ActivityEntity"

**Solution:** Make sure:
1. The .xcdatamodeld file is named exactly `PaintMyTown.xcdatamodeld`
2. Entity names match exactly (case-sensitive)
3. Codegen is set to Manual/None for all entities

### Problem: Tests fail with context errors

**Solution:** Check that:
1. `CoreDataStack.inMemory()` is being used in tests
2. Tests are properly cleaning up in `tearDown()`
3. No shared state between tests

### Problem: Build errors about duplicate symbols

**Solution:**
1. Delete derived data: `Product > Clean Build Folder` (Shift+Cmd+K)
2. Ensure files aren't included multiple times in targets
3. Check that entity class names don't conflict

## Additional Resources

- [Apple Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [WWDC: Core Data Best Practices](https://developer.apple.com/videos/play/wwdc2019/230/)
- Project design document: `/docs/design-document.md`
- Task plan: `/docs/project-task-plan.md`

---

**Tasks Completed:**
- ✅ M0-T07: Create Core Data model (programmatically)
- ✅ M0-T08: Define Activity entity
- ✅ M0-T09: Define LocationSample entity
- ✅ M0-T10: Define Split entity
- ✅ M0-T11: Define CoverageTile entity
- ✅ M0-T12: Define UserSettings entity
- ✅ M0-T13: Create Core Data stack
- ✅ M0-T14: Implement ActivityRepository
- ✅ M0-T15: Implement CoverageTileRepository
- ✅ M0-T16: Create data mappers
- ✅ M0-T17: Write Core Data tests

**Next Tasks:**
- M0-T18 to M0-T25: Permissions Infrastructure
- M0-T26 to M0-T32: App Infrastructure

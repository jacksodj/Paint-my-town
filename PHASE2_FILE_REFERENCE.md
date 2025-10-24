# Phase 2 File Reference - Quick Access Guide

## Core Service Files

### LocationService
- **Protocol**: `/home/user/Paint-my-town/PaintMyTown/Services/LocationServiceProtocol.swift`
- **Implementation**: `/home/user/Paint-my-town/PaintMyTown/Services/LocationService.swift`

### WorkoutService
- **Protocol**: `/home/user/Paint-my-town/PaintMyTown/Services/WorkoutServiceProtocol.swift`
- **Implementation**: `/home/user/Paint-my-town/PaintMyTown/Services/WorkoutService.swift`

### Utilities
- **SplitCalculator**: `/home/user/Paint-my-town/PaintMyTown/Services/SplitCalculator.swift`

## Model Files

### Core Models
- **ActiveWorkout**: `/home/user/Paint-my-town/PaintMyTown/Models/ActiveWorkout.swift`
- **WorkoutMetrics**: `/home/user/Paint-my-town/PaintMyTown/Models/WorkoutMetrics.swift`
- **WorkoutState**: `/home/user/Paint-my-town/PaintMyTown/Models/WorkoutState.swift`
- **PausedInterval**: `/home/user/Paint-my-town/PaintMyTown/Models/PausedInterval.swift`

### Existing Models (Referenced)
- **Activity**: `/home/user/Paint-my-town/PaintMyTown/Models/Activity.swift`
- **ActivityType**: `/home/user/Paint-my-town/PaintMyTown/Models/ActivityType.swift`
- **LocationSample**: `/home/user/Paint-my-town/PaintMyTown/Models/LocationSample.swift`
- **Split**: `/home/user/Paint-my-town/PaintMyTown/Models/Split.swift`
- **DistanceUnit**: `/home/user/Paint-my-town/PaintMyTown/Models/DistanceUnit.swift`
- **AppState**: `/home/user/Paint-my-town/PaintMyTown/Models/AppState.swift`

## Test Files

- **WorkoutServiceTests**: `/home/user/Paint-my-town/PaintMyTownTests/WorkoutServiceTests.swift`
- **SplitCalculatorTests**: `/home/user/Paint-my-town/PaintMyTownTests/SplitCalculatorTests.swift`

## Documentation

- **Implementation Summary**: `/home/user/Paint-my-town/PHASE2_IMPLEMENTATION_SUMMARY.md`
- **File Reference**: `/home/user/Paint-my-town/PHASE2_FILE_REFERENCE.md`
- **Design Document**: `/home/user/Paint-my-town/docs/design-document.md`
- **Task Plan**: `/home/user/Paint-my-town/docs/project-task-plan.md`

## Dependencies & Infrastructure

### Repositories
- **ActivityRepository Protocol**: `/home/user/Paint-my-town/PaintMyTown/Repositories/ActivityRepositoryProtocol.swift`
- **ActivityRepository**: `/home/user/Paint-my-town/PaintMyTown/Repositories/ActivityRepository.swift`

### Utilities
- **Logger**: `/home/user/Paint-my-town/PaintMyTown/Utils/Logger.swift`
- **DependencyContainer**: `/home/user/Paint-my-town/PaintMyTown/Utils/DependencyContainer.swift`
- **PermissionManager**: `/home/user/Paint-my-town/PaintMyTown/Utils/PermissionManager.swift`

### Protocols
- **ServiceProtocol**: `/home/user/Paint-my-town/PaintMyTown/Protocols/ServiceProtocol.swift`
- **RepositoryProtocol**: `/home/user/Paint-my-town/PaintMyTown/Protocols/RepositoryProtocol.swift`

## Directory Structure

```
Paint-my-town/
├── PaintMyTown/
│   ├── Services/
│   │   ├── LocationServiceProtocol.swift
│   │   ├── LocationService.swift
│   │   ├── WorkoutServiceProtocol.swift
│   │   ├── WorkoutService.swift
│   │   └── SplitCalculator.swift
│   ├── Models/
│   │   ├── ActiveWorkout.swift
│   │   ├── WorkoutMetrics.swift
│   │   ├── WorkoutState.swift
│   │   └── PausedInterval.swift
│   ├── Repositories/
│   │   ├── ActivityRepositoryProtocol.swift
│   │   └── ActivityRepository.swift
│   ├── Utils/
│   │   ├── Logger.swift
│   │   └── DependencyContainer.swift
│   └── Protocols/
│       └── ServiceProtocol.swift
├── PaintMyTownTests/
│   ├── WorkoutServiceTests.swift
│   └── SplitCalculatorTests.swift
└── docs/
    ├── design-document.md
    └── project-task-plan.md
```

## Usage Examples

### Starting a Workout
```swift
let workoutService = DependencyContainer.shared.resolve(WorkoutServiceProtocol.self)
let workout = try workoutService.startWorkout(type: .run)
```

### Observing Metrics
```swift
workoutService.metricsPublisher
    .sink { metrics in
        print("Distance: \(metrics.distance)m")
        print("Pace: \(metrics.averagePace)s/km")
    }
    .store(in: &cancellables)
```

### Ending a Workout
```swift
let activity = try workoutService.endWorkout()
try await repository.create(activity: activity)
```

## Key Classes & Protocols

| Component | Type | Purpose |
|-----------|------|---------|
| LocationServiceProtocol | Protocol | GPS tracking interface |
| LocationService | Class | GPS tracking implementation |
| WorkoutServiceProtocol | Protocol | Workout management interface |
| WorkoutService | Class | Workout lifecycle management |
| SplitCalculator | Class | Split calculation utility |
| ActiveWorkout | Class (ObservableObject) | In-memory workout state |
| WorkoutMetrics | Struct | Real-time metrics data |
| WorkoutState | Enum | Workout state machine |
| PausedInterval | Struct | Pause tracking |


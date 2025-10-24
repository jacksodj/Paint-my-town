# Paint the Town — Detailed Design Document

Version: 1.0
Last Updated: 2025-10-23

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [Layer Architecture](#2-layer-architecture)
3. [Core Components](#3-core-components)
4. [Data Architecture](#4-data-architecture)
5. [Service Layer](#5-service-layer)
6. [UI Architecture](#6-ui-architecture)
7. [Navigation Flow](#7-navigation-flow)
8. [State Management](#8-state-management)
9. [Performance Optimization](#9-performance-optimization)
10. [Security & Privacy](#10-security--privacy)

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (SwiftUI Views, ViewModels, Coordinators)              │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  (Use Cases, Business Logic, Domain Models)             │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  (Repositories, Core Data, Services)                    │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                    System Services                       │
│  (CoreLocation, HealthKit, MapKit, FileSystem)          │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Design Patterns

- **MVVM (Model-View-ViewModel)**: Primary architectural pattern
- **Repository Pattern**: Data access abstraction
- **Coordinator Pattern**: Navigation management
- **Dependency Injection**: Service and dependency management
- **Observer Pattern**: State updates via Combine
- **Strategy Pattern**: Coverage algorithms (Heatmap vs Area Fill)

---

## 2. Layer Architecture

### 2.1 Presentation Layer

**Components:**
- SwiftUI Views (declarative UI)
- ViewModels (ObservableObject)
- Coordinators (navigation logic)
- View Helpers & Extensions

**Responsibilities:**
- Render UI
- Handle user interactions
- Display data from ViewModels
- No business logic or direct data access

### 2.2 Domain Layer

**Components:**
- Use Cases (business logic)
- Domain Models (pure Swift structs/classes)
- Business Rules & Validation
- Domain Protocols

**Responsibilities:**
- Core business logic
- Data transformation
- Validation rules
- Platform-agnostic code

### 2.3 Data Layer

**Components:**
- Repositories (data access interface)
- Core Data Stack
- Data Models (NSManagedObject)
- Data Mappers (Core Data ↔ Domain)

**Responsibilities:**
- Data persistence
- CRUD operations
- Data synchronization
- Cache management

---

## 3. Core Components

### 3.1 Location Manager

```swift
protocol LocationServiceProtocol {
    var isAuthorized: Bool { get }
    var currentLocation: CLLocation? { get }
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }

    func requestPermissions()
    func startTracking(activityType: ActivityType)
    func stopTracking()
    func pauseTracking()
    func resumeTracking()
}

class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private var trackingState: TrackingState = .stopped

    // GPS smoothing and filtering
    private let horizontalAccuracyThreshold: CLLocationDistance = 20.0
    private let minimumDisplacementMeters: CLLocationDistance = 5.0
}
```

**Features:**
- Background location updates
- GPS filtering (accuracy, speed, displacement)
- Pause detection (stationary timeout)
- Battery optimization
- Error handling and recovery

### 3.2 Workout Manager

```swift
protocol WorkoutServiceProtocol {
    var activeWorkout: ActiveWorkout? { get }

    func startWorkout(type: ActivityType) -> ActiveWorkout
    func pauseWorkout()
    func resumeWorkout()
    func endWorkout() -> Activity
    func cancelWorkout()
}

class WorkoutService: WorkoutServiceProtocol {
    private let locationService: LocationServiceProtocol
    private let repository: ActivityRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol?

    // Real-time metrics calculation
    private var distanceCalculator: DistanceCalculator
    private var splitCalculator: SplitCalculator
    private var elevationTracker: ElevationTracker
}
```

**Features:**
- Real-time distance/pace/elevation
- Auto-pause detection
- Split tracking (per km/mi)
- Memory-efficient location buffering
- Background persistence

### 3.3 Coverage Engine

```swift
protocol CoverageServiceProtocol {
    func calculateCoverage(
        activities: [Activity],
        filter: CoverageFilter
    ) async -> CoverageResult

    func generateHeatmap(
        activities: [Activity],
        resolution: HeatmapResolution
    ) async -> HeatmapOverlay

    func generateAreaFill(
        activities: [Activity],
        tileSize: TileSize
    ) async -> AreaFillOverlay
}

enum CoverageAlgorithm {
    case heatmap(resolution: HeatmapResolution)
    case areaFill(tileSize: TileSize, bufferMeters: Double)
    case routeLines(width: Double)
}
```

**Heatmap Algorithm:**
1. Grid-based density calculation
2. Gaussian blur smoothing
3. Color gradient mapping (cold → hot)
4. Tile-based rendering for performance

**Area Fill Algorithm:**
1. Convert locations to geohash grid
2. Mark tiles as "visited" with buffer radius
3. Aggregate visited tiles across activities
4. Render as polygon overlays

### 3.4 Filter Engine

```swift
class FilterService {
    func applyFilters(
        to activities: [Activity],
        filter: CoverageFilter
    ) -> [Activity] {
        activities
            .filtered(by: filter.dateRange)
            .filtered(by: filter.activityTypes)
            .filtered(by: filter.minDistance)
            .filtered(by: filter.minDuration)
            .filtered(by: filter.paceRange)
    }

    func generateQuickFilters() -> [QuickFilter] {
        [
            .lastWeek,
            .lastMonth,
            .thisYear,
            .runningOnly,
            .longRuns(minKm: 10),
            .fastPace(maxSecPerKm: 300)
        ]
    }
}
```

---

## 4. Data Architecture

### 4.1 Core Data Schema

```
Activity
├─ id: UUID (primary key)
├─ type: String (walk, run, bike)
├─ startDate: Date (indexed)
├─ endDate: Date
├─ distance: Double (meters)
├─ duration: Double (seconds)
├─ elevationGain: Double (meters)
├─ elevationLoss: Double (meters)
├─ averagePace: Double (sec/km)
├─ notes: String?
├─ relationship: locations (→ LocationSample)
└─ relationship: splits (→ Split)

LocationSample
├─ id: UUID
├─ latitude: Double
├─ longitude: Double
├─ altitude: Double
├─ horizontalAccuracy: Double
├─ verticalAccuracy: Double
├─ timestamp: Date
├─ speed: Double
└─ relationship: activity (→ Activity)

Split
├─ id: UUID
├─ distance: Double (km or mi)
├─ duration: Double (seconds)
├─ pace: Double (sec/km)
├─ elevationGain: Double
└─ relationship: activity (→ Activity)

CoverageTile
├─ geohash: String (indexed)
├─ latitude: Double
├─ longitude: Double
├─ visitCount: Int32
├─ firstVisited: Date
├─ lastVisited: Date
└─ relationship: activities (→ Activity, many-to-many)

UserSettings
├─ id: UUID
├─ distanceUnit: String (km/mi)
├─ mapType: String (standard/satellite/hybrid)
├─ coverageAlgorithm: String
├─ autoStartWorkout: Bool
├─ autoPauseEnabled: Bool
├─ healthKitEnabled: Bool
└─ defaultActivityType: String
```

### 4.2 Repository Pattern

```swift
protocol ActivityRepositoryProtocol {
    func create(activity: Activity) async throws -> Activity
    func fetchAll() async throws -> [Activity]
    func fetch(filter: ActivityFilter) async throws -> [Activity]
    func fetch(id: UUID) async throws -> Activity?
    func update(activity: Activity) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
}

protocol CoverageTileRepositoryProtocol {
    func upsertTiles(_ tiles: [CoverageTile]) async throws
    func fetchTiles(in region: MKCoordinateRegion) async throws -> [CoverageTile]
    func fetchTiles(matching geohashes: [String]) async throws -> [CoverageTile]
}
```

### 4.3 Data Persistence Strategy

**Core Data:**
- Primary persistent store
- Background context for imports
- Main context for UI updates
- Batch operations for bulk inserts

**File System:**
- GPX exports (Documents directory)
- Temporary workout files (Caches directory)
- App preferences (UserDefaults)

**CloudKit (Optional):**
- Sync activities across devices
- Conflict resolution strategy
- Privacy-first design (private database)

---

## 5. Service Layer

### 5.1 HealthKit Service

```swift
protocol HealthKitServiceProtocol {
    var isAuthorized: Bool { get }

    func requestAuthorization() async throws
    func saveWorkout(_ activity: Activity) async throws
    func saveRoute(locations: [CLLocation], for workout: HKWorkout) async throws
    func fetchWorkouts(startDate: Date, endDate: Date) async throws -> [HKWorkout]
}

class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute()
    ]

    private let typesToRead: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute(),
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]
}
```

### 5.2 GPX Service

```swift
protocol GPXServiceProtocol {
    func export(activity: Activity) async throws -> URL
    func exportBatch(activities: [Activity]) async throws -> URL // ZIP file
    func importGPX(from url: URL) async throws -> Activity
}

class GPXService: GPXServiceProtocol {
    func export(activity: Activity) async throws -> URL {
        let gpxString = generateGPXString(for: activity)
        let filename = "activity_\(activity.id)_\(dateFormatter.string(from: activity.startDate)).gpx"
        let url = FileManager.default.documentsDirectory.appendingPathComponent(filename)
        try gpxString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func generateGPXString(for activity: Activity) -> String {
        // GPX 1.1 format with metadata, tracks, and waypoints
    }
}
```

### 5.3 Analytics Service

```swift
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent)
    func trackScreen(_ screen: Screen)
    func trackError(_ error: Error, context: [String: Any])
}

enum AnalyticsEvent {
    case workoutStarted(type: ActivityType)
    case workoutCompleted(distance: Double, duration: Double)
    case filterApplied(filter: CoverageFilter)
    case coverageViewed(algorithm: CoverageAlgorithm)
    case exportRequested(format: ExportFormat)
}

class AnalyticsService: AnalyticsServiceProtocol {
    // Phase 1: OSLog + MetricKit only
    // Phase 2: Optional Firebase

    private let logger = Logger(subsystem: "com.paintmytown.app", category: "analytics")
}
```

---

## 6. UI Architecture

### 6.1 Tab Structure

```
AppCoordinator
├─ RecordTab
│  ├─ RecordView (map + controls)
│  ├─ ActiveWorkoutView (real-time stats)
│  └─ WorkoutSummaryView (post-workout)
│
├─ MapTab
│  ├─ CoverageMapView (coverage overlay)
│  ├─ FilterSheetView (filter controls)
│  └─ MapStylePickerView (map type selector)
│
├─ HistoryTab
│  ├─ ActivityListView (scrollable list)
│  ├─ ActivityDetailView (single activity)
│  └─ ActivityStatsView (charts & graphs)
│
└─ ProfileTab
   ├─ ProfileView (user stats)
   ├─ SettingsView (app preferences)
   ├─ PermissionsView (manage permissions)
   └─ DataManagementView (export/delete)
```

### 6.2 Key View Models

```swift
class RecordViewModel: ObservableObject {
    @Published var trackingState: TrackingState = .stopped
    @Published var currentDistance: Double = 0
    @Published var currentDuration: TimeInterval = 0
    @Published var currentPace: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var currentRoute: [CLLocationCoordinate2D] = []

    private let workoutService: WorkoutServiceProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    func startWorkout(type: ActivityType) { }
    func pauseWorkout() { }
    func resumeWorkout() { }
    func endWorkout() { }
}

class CoverageMapViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var coverageOverlay: MKOverlay?
    @Published var filter: CoverageFilter = .default
    @Published var algorithm: CoverageAlgorithm = .heatmap(resolution: .medium)
    @Published var isLoading: Bool = false

    private let coverageService: CoverageServiceProtocol
    private let activityRepository: ActivityRepositoryProtocol

    func loadCoverage() async { }
    func applyFilter(_ filter: CoverageFilter) async { }
    func changeAlgorithm(_ algorithm: CoverageAlgorithm) async { }
}
```

### 6.3 SwiftUI Component Library

**Reusable Components:**
- `StatCard`: Display metric with label, value, unit
- `ActivityTypeButton`: Icon + label for activity selection
- `FilterChip`: Quick filter toggle button
- `MapControlButton`: Overlay control button (map style, layers)
- `WorkoutControlButton`: Start/pause/stop with animation
- `ProgressRing`: Circular progress indicator
- `ChartView`: Generic chart wrapper (line, bar, area)
- `EmptyStateView`: No data placeholder with action

---

## 7. Navigation Flow

### 7.1 Coordinator Protocol

```swift
protocol Coordinator {
    var navigationController: UINavigationController? { get }
    var childCoordinators: [Coordinator] { get set }

    func start()
}

class AppCoordinator: Coordinator {
    private let tabBarController = UITabBarController()

    func start() {
        let recordCoordinator = RecordCoordinator()
        let mapCoordinator = MapCoordinator()
        let historyCoordinator = HistoryCoordinator()
        let profileCoordinator = ProfileCoordinator()

        childCoordinators = [
            recordCoordinator,
            mapCoordinator,
            historyCoordinator,
            profileCoordinator
        ]

        // Configure tab bar
    }
}
```

### 7.2 Deep Linking

```swift
enum DeepLink {
    case workout(id: UUID)
    case startWorkout(type: ActivityType)
    case coverage(filter: CoverageFilter)
    case settings
}

class DeepLinkHandler {
    func handle(_ deepLink: DeepLink, coordinator: AppCoordinator) {
        // Navigate to appropriate screen
    }
}
```

---

## 8. State Management

### 8.1 Global App State

```swift
class AppState: ObservableObject {
    @Published var isLocationAuthorized: Bool = false
    @Published var isHealthKitAuthorized: Bool = false
    @Published var activeWorkout: ActiveWorkout?
    @Published var userSettings: UserSettings

    static let shared = AppState()
}
```

### 8.2 Combine Publishers

```swift
// Location updates
locationService.locationPublisher
    .filter { $0.horizontalAccuracy < 20 }
    .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
    .sink { location in
        // Update UI
    }

// Workout metrics
workoutService.metricsPublisher
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .sink { metrics in
        viewModel.updateMetrics(metrics)
    }
```

---

## 9. Performance Optimization

### 9.1 Location Data Optimization

- **Decimation**: Reduce point density for old activities (keep every Nth point)
- **Simplification**: Douglas-Peucker algorithm for route simplification
- **Batch Loading**: Lazy load location data only when viewing details
- **Indexing**: Geospatial indexing for fast region queries

### 9.2 Coverage Rendering

- **Tile-based**: Render only visible map tiles
- **Level of Detail**: Different resolutions based on zoom level
- **Caching**: Cache rendered overlays in memory
- **Background Processing**: Calculate coverage on background thread

### 9.3 Core Data Optimization

- **Faulting**: Use faults for large location arrays
- **Batch Fetching**: Fetch in batches of 100 activities
- **Predicates**: Efficient fetch predicates with indexes
- **Async/Await**: Non-blocking database operations

---

## 10. Security & Privacy

### 10.1 Data Privacy

- All location data stored locally by default
- Optional CloudKit sync with user consent
- No third-party analytics without opt-in
- Clear data deletion process

### 10.2 Permission Flow

```swift
enum PermissionState {
    case notDetermined
    case denied
    case authorized
    case restricted
}

class PermissionManager {
    func checkLocationPermission() -> PermissionState { }
    func requestLocationPermission() async -> PermissionState { }

    func checkHealthKitPermission() -> PermissionState { }
    func requestHealthKitPermission() async -> PermissionState { }

    // User-friendly explanations for each permission
    func permissionRationale(for permission: Permission) -> String { }
}
```

### 10.3 Info.plist Keys

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

---

## Appendix A: Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI Framework | SwiftUI | Modern, declarative, less code |
| Database | Core Data | Native, mature, CloudKit integration |
| Async | async/await + Combine | Modern Swift concurrency |
| DI Framework | None (manual) | Simple, explicit, testable |
| Testing | XCTest + ViewInspector | Native, reliable |
| Maps | MapKit | Native, performant, free |

---

## Appendix B: Third-Party Dependencies

**Phase 1 (MVP):**
- None (pure native frameworks)

**Phase 2 (Optional):**
- Firebase Analytics (analytics)
- Turf-swift (geospatial calculations)
- Charts (iOS 16+ native)

---

*End of Design Document*

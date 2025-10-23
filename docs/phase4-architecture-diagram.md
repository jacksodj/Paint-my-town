# Phase 4 Architecture Diagram

## Complete Navigation & State Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PaintMyTownApp                              │
│  ┌──────────────────┐         ┌────────────────────┐               │
│  │   @StateObject   │         │   @StateObject     │               │
│  │    AppState      │◄────────┤  AppCoordinator    │               │
│  │   (Singleton)    │         │                    │               │
│  └──────────────────┘         └────────────────────┘               │
│           │                             │                           │
│           │ Environment                 │ Coordinator               │
│           │ Object                      │ Hierarchy                 │
└───────────┼─────────────────────────────┼───────────────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AppTabView                                 │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                        TabView                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
            │
            ├─────────────┬─────────────┬─────────────┬──────────────┐
            ▼             ▼             ▼             ▼              ▼
    ┌─────────────┐ ┌──────────┐ ┌───────────┐ ┌────────────┐
    │ RecordView  │ │ MapView  │ │HistoryView│ │ProfileView │
    │      +      │ │    +     │ │     +     │ │     +      │
    │  Coordinator│ │Coordinator│ │ Coordinator│ │ Coordinator│
    └─────────────┘ └──────────┘ └───────────┘ └────────────┘
```

## AppCoordinator Deep Dive

```
┌───────────────────────────────────────────────────────────────┐
│                      AppCoordinator                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Properties:                                            │ │
│  │  • @Published selectedTab: Tab                          │ │
│  │  • @Published deepLink: DeepLink?                       │ │
│  │  • childCoordinators: [Coordinator]                     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Child Coordinators:                                    │ │
│  │  • RecordCoordinator    (Record Tab)                    │ │
│  │  • MapCoordinator       (Map Tab)                       │ │
│  │  • HistoryCoordinator   (History Tab)                   │ │
│  │  • ProfileCoordinator   (Profile Tab)                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Deep Linking:                                          │ │
│  │  • .workout(id: UUID)                                   │ │
│  │  • .startWorkout(type: ActivityType)                    │ │
│  │  • .coverage(filter: CoverageFilter)                    │ │
│  │  • .settings                                            │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

## AppState Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                   AppState (Singleton)                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  @Published Properties:                                  │ │
│  │  • isLocationAuthorized: Bool                            │ │
│  │  • isBackgroundLocationAuthorized: Bool                  │ │
│  │  • isMotionAuthorized: Bool                              │ │
│  │  • isHealthKitAuthorized: Bool                           │ │
│  │  • activeWorkout: ActiveWorkout?                         │ │
│  │  • currentError: AppError?                               │ │
│  │  • isLoading: Bool                                       │ │
│  │  • isInBackground: Bool                                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Dependencies:                                           │ │
│  │  • settings: UserDefaultsManager                         │ │
│  │  • logger: Logger                                        │ │
│  │  • permissionManager: PermissionManager                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Combine Publishers:                                     │ │
│  │  • Observes permission changes                           │ │
│  │  • Observes workout state changes                        │ │
│  │  • Logs state transitions                                │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Utilities Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                    Utility Infrastructure                       │
│  ┌───────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │    Logger     │  │UserDefaults      │  │Permission      │  │
│  │               │  │Manager           │  │Manager         │  │
│  │ • OSLog wrap  │  │                  │  │                │  │
│  │ • Categories  │  │ • Type-safe      │  │ • Location     │  │
│  │ • Debug mode  │  │ • @UserDefault   │  │ • Motion       │  │
│  │               │  │ • Codable types  │  │ • HealthKit    │  │
│  └───────────────┘  └──────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     Error Handling Chain                        │
│                                                                 │
│  Error Occurs                                                   │
│       │                                                         │
│       ▼                                                         │
│  AppError Created                                               │
│       │                                                         │
│       ├─────► shouldLog? ─────► Logger                          │
│       │                                                         │
│       ├─────► shouldShowAlert? ─────► ErrorView/Alert           │
│       │                                                         │
│       └─────► AppState.setError() ─────► Global Error Handler   │
│                                                                 │
│  ErrorView Displays:                                            │
│  • Icon (context-appropriate)                                   │
│  • Description (user-friendly)                                  │
│  • Recovery suggestion                                          │
│  • "Try Again" button (if applicable)                           │
│  • "Open Settings" button (if needed)                           │
└─────────────────────────────────────────────────────────────────┘
```

## Tab Navigation Structure

```
┌──────────────────────────────────────────────────────────────────┐
│                          Record Tab                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  RecordCoordinator                                         │ │
│  │  • presentedSheet: RecordSheet?                            │ │
│  │  • navigationPath: NavigationPath                          │ │
│  │                                                            │ │
│  │  Future Navigation:                                        │ │
│  │  • RecordView → ActiveWorkoutView                          │ │
│  │  • RecordView → WorkoutSummaryView                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                           Map Tab                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  MapCoordinator                                            │ │
│  │  • presentedSheet: MapSheet?                               │ │
│  │  • activeFilter: CoverageFilter                            │ │
│  │                                                            │ │
│  │  Future Navigation:                                        │ │
│  │  • MapView → FilterSheetView                               │ │
│  │  • MapView → MapStylePickerView                            │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                         History Tab                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  HistoryCoordinator                                        │ │
│  │  • presentedSheet: HistorySheet?                           │ │
│  │  • selectedWorkoutId: UUID?                                │ │
│  │                                                            │ │
│  │  Future Navigation:                                        │ │
│  │  • HistoryView → ActivityDetailView                        │ │
│  │  • HistoryView → SearchSheet                               │ │
│  │  • ActivityDetailView → ActivityStatsView                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                         Profile Tab                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ProfileCoordinator                                        │ │
│  │  • presentedSheet: ProfileSheet?                           │ │
│  │                                                            │ │
│  │  Future Navigation:                                        │ │
│  │  • ProfileView → SettingsView                              │ │
│  │  • ProfileView → PermissionsView                           │ │
│  │  • ProfileView → DataManagementView                        │ │
│  │  • ProfileView → AboutView                                 │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                        Data Flow                               │
│                                                                │
│  User Interaction                                              │
│       │                                                        │
│       ▼                                                        │
│  SwiftUI View                                                  │
│       │                                                        │
│       ├──── @EnvironmentObject ────► AppState                  │
│       │                                                        │
│       ├──── @ObservedObject ────────► Coordinator              │
│       │                                                        │
│       └──── User Action ─────────────► Coordinator Method      │
│                                             │                  │
│                                             ▼                  │
│                                        Update State            │
│                                             │                  │
│                                             ├─► AppState       │
│                                             │                  │
│                                             ├─► Logger         │
│                                             │                  │
│                                             └─► Navigation     │
│                                                                │
│  State Change                                                  │
│       │                                                        │
│       ▼                                                        │
│  SwiftUI View Update (Automatic)                               │
└────────────────────────────────────────────────────────────────┘
```

## Coordinator Pattern Implementation

```
┌────────────────────────────────────────────────────────────────┐
│                  Coordinator Protocol                          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  protocol Coordinator: AnyObject {                       │ │
│  │      var childCoordinators: [Coordinator] { get set }    │ │
│  │      func start()                                        │ │
│  │      func addChild(_ coordinator: Coordinator)           │ │
│  │      func removeChild(_ coordinator: Coordinator)        │ │
│  │  }                                                       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  Benefits:                                                     │
│  • Decouples navigation from views                            │
│  • Testable navigation logic                                  │
│  • Hierarchical coordinator management                        │
│  • Reusable navigation patterns                               │
│  • Clear separation of concerns                               │
└────────────────────────────────────────────────────────────────┘
```

## Logger Categories & Usage

```
┌────────────────────────────────────────────────────────────────┐
│                     Logger Categories                          │
│                                                                │
│  LogCategory.network                                           │
│      ├─ API requests/responses                                 │
│      └─ Network errors                                         │
│                                                                │
│  LogCategory.database                                          │
│      ├─ Core Data operations                                   │
│      ├─ CRUD operations                                        │
│      └─ Query performance                                      │
│                                                                │
│  LogCategory.location                                          │
│      ├─ GPS updates                                            │
│      ├─ Location permissions                                   │
│      └─ Tracking state changes                                 │
│                                                                │
│  LogCategory.ui                                                │
│      ├─ Screen transitions                                     │
│      ├─ User interactions                                      │
│      └─ View lifecycle                                         │
│                                                                │
│  LogCategory.workout                                           │
│      ├─ Workout state changes                                  │
│      ├─ Real-time metrics                                      │
│      └─ Workout persistence                                    │
│                                                                │
│  LogCategory.permissions                                       │
│      ├─ Permission requests                                    │
│      ├─ Authorization changes                                  │
│      └─ Permission errors                                      │
│                                                                │
│  LogCategory.coverage                                          │
│      ├─ Coverage calculations                                  │
│      ├─ Algorithm selection                                    │
│      └─ Tile generation                                        │
│                                                                │
│  LogCategory.general                                           │
│      ├─ App lifecycle                                          │
│      ├─ Settings changes                                       │
│      └─ Miscellaneous events                                   │
└────────────────────────────────────────────────────────────────┘
```

## UserDefaults Settings Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                 UserDefaultsManager                            │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Property Wrappers:                                      │ │
│  │  @UserDefault<T>          - For basic types              │ │
│  │  @UserDefaultCodable<T>   - For Codable types            │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Settings Categories:                                    │ │
│  │                                                          │ │
│  │  Display & Units:                                        │ │
│  │  • distanceUnit (km/mi)                                  │ │
│  │  • showSpeedInsteadOfPace                                │ │
│  │  • splitDistance                                         │ │
│  │                                                          │ │
│  │  Map Preferences:                                        │ │
│  │  • mapType (standard/satellite/hybrid)                   │ │
│  │  • coverageAlgorithm (heatmap/areaFill/routeLines)       │ │
│  │  • coverageTileSize                                      │ │
│  │                                                          │ │
│  │  Workout Settings:                                       │ │
│  │  • defaultActivityType                                   │ │
│  │  • autoStartWorkout                                      │ │
│  │  • autoPauseEnabled                                      │ │
│  │  • voiceAnnouncementEnabled                              │ │
│  │                                                          │ │
│  │  Integration:                                            │ │
│  │  • healthKitEnabled                                      │ │
│  │                                                          │ │
│  │  App State:                                              │ │
│  │  • hasCompletedOnboarding                                │ │
│  │  • lastSelectedTab                                       │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Integration with Future Features

```
┌────────────────────────────────────────────────────────────────┐
│                    M1: Recording Engine                        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  RecordCoordinator + RecordViewModel                     │ │
│  │       ↓                                                  │ │
│  │  LocationService + WorkoutService                        │ │
│  │       ↓                                                  │ │
│  │  AppState.activeWorkout                                  │ │
│  │       ↓                                                  │ │
│  │  RecordView (live updates)                               │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                  M2: Coverage & Filters                        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  MapCoordinator.activeFilter                             │ │
│  │       ↓                                                  │ │
│  │  CoverageService + FilterService                         │ │
│  │       ↓                                                  │ │
│  │  MapView (coverage overlay)                              │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                   M3: History & UI Polish                      │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  HistoryCoordinator.selectedWorkoutId                    │ │
│  │       ↓                                                  │ │
│  │  ActivityRepository                                      │ │
│  │       ↓                                                  │ │
│  │  HistoryView → ActivityDetailView                        │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                  M5: HealthKit & Import                        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  AppState.isHealthKitAuthorized                          │ │
│  │       ↓                                                  │ │
│  │  HealthKitService + GPXService                           │ │
│  │       ↓                                                  │ │
│  │  ProfileView (data management)                           │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Testing Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                       Testing Layers                           │
│                                                                │
│  Unit Tests:                                                   │
│  • Coordinator navigation logic                                │
│  • AppState state management                                   │
│  • UserDefaultsManager with test defaults                      │
│  • AppError message generation                                 │
│  • Logger category selection                                   │
│                                                                │
│  Integration Tests:                                            │
│  • Coordinator → AppState interaction                          │
│  • Permission changes → AppState updates                       │
│  • Deep linking → Navigation flow                              │
│                                                                │
│  UI Tests:                                                     │
│  • Tab switching                                               │
│  • Error alert presentation                                    │
│  • Sheet presentation/dismissal                                │
│  • Navigation stack push/pop                                   │
│                                                                │
│  Manual Tests:                                                 │
│  • Permission request flows                                    │
│  • Settings persistence                                        │
│  • Deep link handling                                          │
│  • App lifecycle (background/foreground)                       │
└────────────────────────────────────────────────────────────────┘
```

---

## Key Architectural Decisions

### 1. Coordinator Pattern
- **Why**: Decouples navigation from views, making views more reusable
- **Benefit**: Testable navigation, clear flow control
- **Trade-off**: Additional boilerplate, but worth it for maintainability

### 2. Singleton AppState
- **Why**: Centralized app-wide state management
- **Benefit**: Single source of truth, easy access
- **Trade-off**: Careful to avoid abuse, keep focused on truly global state

### 3. Property Wrappers for UserDefaults
- **Why**: Type safety, DRY principle
- **Benefit**: Compile-time safety, cleaner code
- **Trade-off**: Initial setup, but saves time long-term

### 4. OSLog Wrapper
- **Why**: Structured logging with categories
- **Benefit**: Privacy-aware, system-integrated, performant
- **Trade-off**: More verbose than print(), but production-ready

### 5. Enum-based Errors
- **Why**: Exhaustive error cases, type-safe
- **Benefit**: LocalizedError support, compiler-enforced handling
- **Trade-off**: More code than throwing errors, but better UX

---

## Performance Considerations

### Main Thread Safety
- All coordinators use `@MainActor`
- AppState uses `@MainActor`
- UI updates guaranteed on main thread

### Memory Management
- Weak references in Combine subscribers
- Coordinator child management prevents leaks
- UserDefaults caching reduces disk access

### Logging Performance
- Debug info only in DEBUG builds
- OSLog is highly optimized
- Async logging doesn't block UI

---

*Architecture designed for scalability, testability, and maintainability*

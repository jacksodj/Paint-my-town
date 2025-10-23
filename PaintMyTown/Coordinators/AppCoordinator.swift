//
//  AppCoordinator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI
import Combine

/// Main application coordinator managing app-level navigation and deep linking
@MainActor
class AppCoordinator: ObservableObject, Coordinator {
    // MARK: - Properties

    var childCoordinators: [Coordinator] = []

    @Published var selectedTab: Tab = .record
    @Published var deepLink: DeepLink?

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    // Tab coordinators
    private(set) var recordCoordinator: RecordCoordinator!
    private(set) var mapCoordinator: MapCoordinator!
    private(set) var historyCoordinator: HistoryCoordinator!
    private(set) var profileCoordinator: ProfileCoordinator!

    // MARK: - Initialization

    init(appState: AppState = .shared) {
        self.appState = appState
    }

    // MARK: - Coordinator

    func start() {
        setupTabCoordinators()
        setupDeepLinking()
    }

    // MARK: - Private Methods

    private func setupTabCoordinators() {
        recordCoordinator = RecordCoordinator(appState: appState)
        mapCoordinator = MapCoordinator(appState: appState)
        historyCoordinator = HistoryCoordinator(appState: appState)
        profileCoordinator = ProfileCoordinator(appState: appState)

        addChild(recordCoordinator)
        addChild(mapCoordinator)
        addChild(historyCoordinator)
        addChild(profileCoordinator)

        recordCoordinator.start()
        mapCoordinator.start()
        historyCoordinator.start()
        profileCoordinator.start()
    }

    private func setupDeepLinking() {
        // Listen for deep link changes
        $deepLink
            .compactMap { $0 }
            .sink { [weak self] deepLink in
                self?.handleDeepLink(deepLink)
            }
            .store(in: &cancellables)
    }

    // MARK: - Deep Linking

    /// Handles deep link navigation
    func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .workout(let id):
            selectedTab = .history
            historyCoordinator.showWorkout(id: id)

        case .startWorkout(let type):
            selectedTab = .record
            recordCoordinator.startWorkout(type: type)

        case .coverage(let filter):
            selectedTab = .map
            mapCoordinator.applyFilter(filter)

        case .settings:
            selectedTab = .profile
            profileCoordinator.showSettings()
        }

        // Clear deep link after handling
        self.deepLink = nil
    }

    /// Sets a deep link to be handled
    func setDeepLink(_ deepLink: DeepLink) {
        self.deepLink = deepLink
    }

    // MARK: - Tab Selection

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
}

// MARK: - Supporting Types

/// Available tabs in the app
enum Tab: String, CaseIterable {
    case record
    case map
    case history
    case profile

    var title: String {
        switch self {
        case .record: return "Record"
        case .map: return "Map"
        case .history: return "History"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .record: return "figure.walk"
        case .map: return "map"
        case .history: return "list.bullet"
        case .profile: return "person.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .record: return "figure.walk"
        case .map: return "map.fill"
        case .history: return "list.bullet"
        case .profile: return "person.circle.fill"
        }
    }
}

/// Deep link destinations
enum DeepLink {
    case workout(id: UUID)
    case startWorkout(type: ActivityType)
    case coverage(filter: CoverageFilter)
    case settings
}

/// Activity types
enum ActivityType: String, CaseIterable, Codable {
    case walk
    case run
    case bike

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .bike: return "bicycle"
        }
    }
}

/// Coverage filter placeholder (to be implemented in M2)
struct CoverageFilter: Equatable {
    var dateRange: DateRange?
    var activityTypes: Set<ActivityType>
    var minDistance: Double?
    var minDuration: TimeInterval?

    static let `default` = CoverageFilter(
        dateRange: nil,
        activityTypes: Set(ActivityType.allCases),
        minDistance: nil,
        minDuration: nil
    )
}

/// Date range for filtering
struct DateRange: Equatable {
    let start: Date
    let end: Date
}

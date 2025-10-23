//
//  UserDefaultsManager.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Type-safe wrapper for UserDefaults providing app settings storage
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults

    init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

/// Property wrapper for Codable types in UserDefaults
@propertyWrapper
struct UserDefaultCodable<T: Codable> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults

    init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            guard let data = userDefaults.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: key)
            }
        }
    }
}

/// Centralized manager for all app settings stored in UserDefaults
final class UserDefaultsManager {
    // MARK: - Singleton

    static let shared = UserDefaultsManager()

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let distanceUnit = "distanceUnit"
        static let mapType = "mapType"
        static let coverageAlgorithm = "coverageAlgorithm"
        static let autoStartWorkout = "autoStartWorkout"
        static let autoPauseEnabled = "autoPauseEnabled"
        static let healthKitEnabled = "healthKitEnabled"
        static let defaultActivityType = "defaultActivityType"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSelectedTab = "lastSelectedTab"
        static let showSpeedInsteadOfPace = "showSpeedInsteadOfPace"
        static let voiceAnnouncementEnabled = "voiceAnnouncementEnabled"
        static let splitDistance = "splitDistance"
        static let coverageTileSize = "coverageTileSize"
    }

    // MARK: - Settings Properties

    /// Distance unit preference (kilometers or miles)
    @UserDefault(key: Keys.distanceUnit, defaultValue: DistanceUnit.kilometers.rawValue)
    var distanceUnitRaw: String

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: distanceUnitRaw) ?? .kilometers }
        set { distanceUnitRaw = newValue.rawValue }
    }

    /// Map type preference
    @UserDefault(key: Keys.mapType, defaultValue: MapType.standard.rawValue)
    var mapTypeRaw: String

    var mapType: MapType {
        get { MapType(rawValue: mapTypeRaw) ?? .standard }
        set { mapTypeRaw = newValue.rawValue }
    }

    /// Coverage visualization algorithm
    @UserDefault(key: Keys.coverageAlgorithm, defaultValue: CoverageAlgorithmType.heatmap.rawValue)
    var coverageAlgorithmRaw: String

    var coverageAlgorithm: CoverageAlgorithmType {
        get { CoverageAlgorithmType(rawValue: coverageAlgorithmRaw) ?? .heatmap }
        set { coverageAlgorithmRaw = newValue.rawValue }
    }

    /// Auto-start workout when app opens
    @UserDefault(key: Keys.autoStartWorkout, defaultValue: false)
    var autoStartWorkout: Bool

    /// Auto-pause when user stops moving
    @UserDefault(key: Keys.autoPauseEnabled, defaultValue: true)
    var autoPauseEnabled: Bool

    /// HealthKit integration enabled
    @UserDefault(key: Keys.healthKitEnabled, defaultValue: false)
    var healthKitEnabled: Bool

    /// Default activity type for new workouts
    @UserDefault(key: Keys.defaultActivityType, defaultValue: ActivityType.walk.rawValue)
    var defaultActivityTypeRaw: String

    var defaultActivityType: ActivityType {
        get { ActivityType(rawValue: defaultActivityTypeRaw) ?? .walk }
        set { defaultActivityTypeRaw = newValue.rawValue }
    }

    /// Whether user has completed onboarding
    @UserDefault(key: Keys.hasCompletedOnboarding, defaultValue: false)
    var hasCompletedOnboarding: Bool

    /// Last selected tab (for restoring state)
    @UserDefault(key: Keys.lastSelectedTab, defaultValue: Tab.record.rawValue)
    var lastSelectedTabRaw: String

    var lastSelectedTab: Tab {
        get { Tab(rawValue: lastSelectedTabRaw) ?? .record }
        set { lastSelectedTabRaw = newValue.rawValue }
    }

    /// Show speed instead of pace
    @UserDefault(key: Keys.showSpeedInsteadOfPace, defaultValue: false)
    var showSpeedInsteadOfPace: Bool

    /// Voice announcement during workouts
    @UserDefault(key: Keys.voiceAnnouncementEnabled, defaultValue: true)
    var voiceAnnouncementEnabled: Bool

    /// Split distance in meters (1km or 1mi)
    @UserDefault(key: Keys.splitDistance, defaultValue: 1000.0)
    var splitDistance: Double

    /// Coverage tile size in meters
    @UserDefault(key: Keys.coverageTileSize, defaultValue: 100.0)
    var coverageTileSize: Double

    // MARK: - Methods

    /// Resets all settings to default values
    func resetToDefaults() {
        distanceUnit = .kilometers
        mapType = .standard
        coverageAlgorithm = .heatmap
        autoStartWorkout = false
        autoPauseEnabled = true
        healthKitEnabled = false
        defaultActivityType = .walk
        showSpeedInsteadOfPace = false
        voiceAnnouncementEnabled = true
        splitDistance = 1000.0
        coverageTileSize = 100.0

        Logger.shared.info("Reset all settings to defaults", category: .general)
    }

    /// Clears all UserDefaults for the app (useful for testing)
    func clearAll() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            Logger.shared.info("Cleared all UserDefaults", category: .general)
        }
    }
}

// MARK: - Supporting Types

/// Distance unit enum
enum DistanceUnit: String, Codable, CaseIterable {
    case kilometers = "km"
    case miles = "mi"

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }

    var shortName: String {
        rawValue
    }

    /// Conversion factor to meters
    var metersPerUnit: Double {
        switch self {
        case .kilometers: return 1000.0
        case .miles: return 1609.344
        }
    }
}

/// Map type enum
enum MapType: String, Codable, CaseIterable {
    case standard
    case satellite
    case hybrid

    var displayName: String {
        rawValue.capitalized
    }
}

/// Coverage algorithm type
enum CoverageAlgorithmType: String, Codable, CaseIterable {
    case heatmap
    case areaFill
    case routeLines

    var displayName: String {
        switch self {
        case .heatmap: return "Heatmap"
        case .areaFill: return "Area Fill"
        case .routeLines: return "Route Lines"
        }
    }

    var description: String {
        switch self {
        case .heatmap: return "Shows density of your activities with a color gradient"
        case .areaFill: return "Fills tiles you've visited, like a game map"
        case .routeLines: return "Shows your exact routes as lines"
        }
    }
}

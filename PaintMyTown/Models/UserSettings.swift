//
//  UserSettings.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Domain model representing user preferences and settings
struct UserSettings: Identifiable, Codable {
    let id: UUID
    var distanceUnit: DistanceUnit
    var mapType: MapType
    var coverageAlgorithm: CoverageAlgorithmType
    var autoStartWorkout: Bool
    var autoPauseEnabled: Bool
    var healthKitEnabled: Bool
    var defaultActivityType: ActivityType

    init(
        id: UUID = UUID(),
        distanceUnit: DistanceUnit = .kilometers,
        mapType: MapType = .standard,
        coverageAlgorithm: CoverageAlgorithmType = .heatmap,
        autoStartWorkout: Bool = false,
        autoPauseEnabled: Bool = true,
        healthKitEnabled: Bool = false,
        defaultActivityType: ActivityType = .run
    ) {
        self.id = id
        self.distanceUnit = distanceUnit
        self.mapType = mapType
        self.coverageAlgorithm = coverageAlgorithm
        self.autoStartWorkout = autoStartWorkout
        self.autoPauseEnabled = autoPauseEnabled
        self.healthKitEnabled = healthKitEnabled
        self.defaultActivityType = defaultActivityType
    }
}

/// Map display type
enum MapType: String, CaseIterable, Codable {
    case standard
    case satellite
    case hybrid

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .satellite:
            return "Satellite"
        case .hybrid:
            return "Hybrid"
        }
    }
}

/// Coverage algorithm type
enum CoverageAlgorithmType: String, CaseIterable, Codable {
    case heatmap
    case areaFill
    case routeLines

    var displayName: String {
        switch self {
        case .heatmap:
            return "Heatmap"
        case .areaFill:
            return "Area Fill"
        case .routeLines:
            return "Route Lines"
        }
    }
}

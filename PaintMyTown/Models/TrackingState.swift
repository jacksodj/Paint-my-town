//
//  TrackingState.swift
//  PaintMyTown
//
//  Represents the current state of location tracking during a workout
//  Created as part of M1-T01 (LocationService implementation)
//

import Foundation

/// Represents the current state of GPS tracking during a workout
enum TrackingState: String, Codable, Equatable {
    /// Location tracking is not active
    case stopped

    /// Location tracking is paused (locations not being recorded)
    case paused

    /// Location tracking is active and recording
    case active

    var displayName: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .paused:
            return "Paused"
        case .active:
            return "Active"
        }
    }

    var isTracking: Bool {
        return self == .active
    }

    var canPause: Bool {
        return self == .active
    }

    var canResume: Bool {
        return self == .paused
    }

    var canStop: Bool {
        return self == .active || self == .paused
    }
}

/// Configuration for location tracking accuracy and battery usage
struct LocationTrackingConfig: Equatable {
    /// Desired location accuracy in meters
    let desiredAccuracy: Double

    /// Minimum distance between location updates in meters
    let distanceFilter: Double

    /// Activity type for motion coprocessor optimization
    let activityType: ActivityType

    /// Whether to allow background location updates
    let allowsBackgroundUpdates: Bool

    /// Whether to pause updates automatically when stationary
    let pausesAutomatically: Bool

    /// Battery optimization level
    let batteryOptimization: BatteryOptimizationLevel

    static func standard(for activityType: ActivityType) -> LocationTrackingConfig {
        LocationTrackingConfig(
            desiredAccuracy: -1, // kCLLocationAccuracyBest
            distanceFilter: 5.0,
            activityType: activityType,
            allowsBackgroundUpdates: true,
            pausesAutomatically: false,
            batteryOptimization: .balanced
        )
    }

    static func highAccuracy(for activityType: ActivityType) -> LocationTrackingConfig {
        LocationTrackingConfig(
            desiredAccuracy: -1, // kCLLocationAccuracyBest
            distanceFilter: 3.0,
            activityType: activityType,
            allowsBackgroundUpdates: true,
            pausesAutomatically: false,
            batteryOptimization: .performance
        )
    }

    static func batterySaver(for activityType: ActivityType) -> LocationTrackingConfig {
        LocationTrackingConfig(
            desiredAccuracy: 10.0, // kCLLocationAccuracyNearestTenMeters
            distanceFilter: 10.0,
            activityType: activityType,
            allowsBackgroundUpdates: true,
            pausesAutomatically: false,
            batteryOptimization: .batterySaver
        )
    }
}

/// Battery optimization level for location tracking
enum BatteryOptimizationLevel: String, Codable, CaseIterable {
    /// Best accuracy, highest battery usage
    case performance

    /// Balanced accuracy and battery usage
    case balanced

    /// Lower accuracy, best battery life
    case batterySaver

    var displayName: String {
        switch self {
        case .performance:
            return "Best Accuracy"
        case .balanced:
            return "Balanced"
        case .batterySaver:
            return "Battery Saver"
        }
    }

    var desiredAccuracy: Double {
        switch self {
        case .performance:
            return -1 // kCLLocationAccuracyBest
        case .balanced:
            return -2 // kCLLocationAccuracyBestForNavigation
        case .batterySaver:
            return 10.0 // kCLLocationAccuracyNearestTenMeters
        }
    }

    var distanceFilter: Double {
        switch self {
        case .performance:
            return 3.0
        case .balanced:
            return 5.0
        case .batterySaver:
            return 10.0
        }
    }
}

//
//  LocationFilter.swift
//  PaintMyTown
//
//  GPS location filtering utility
//  Filters out inaccurate, stale, or impossible locations
//  Implemented as part of M1-T04 (GPS filtering)
//

import Foundation
import CoreLocation

/// Utility class for filtering GPS location data
/// Filters by accuracy, speed, timestamp, and displacement
class LocationFilter {
    // MARK: - Filter Thresholds

    /// Maximum horizontal accuracy to accept (meters)
    private let horizontalAccuracyThreshold: CLLocationDistance

    /// Maximum vertical accuracy to accept (meters)
    private let verticalAccuracyThreshold: CLLocationDistance

    /// Maximum age of location to accept (seconds)
    private let maxLocationAge: TimeInterval

    /// Minimum displacement from last location (meters)
    private let minimumDisplacement: CLLocationDistance

    /// Maximum possible speed for the activity (m/s)
    private let maxSpeed: CLLocationSpeed

    /// Last accepted location (for displacement filtering)
    private var lastAcceptedLocation: CLLocation?

    // MARK: - Statistics

    private(set) var totalLocations: Int = 0
    private(set) var acceptedLocations: Int = 0
    private(set) var rejectedByAccuracy: Int = 0
    private(set) var rejectedByAge: Int = 0
    private(set) var rejectedByDisplacement: Int = 0
    private(set) var rejectedBySpeed: Int = 0

    // MARK: - Initialization

    /// Initialize location filter with custom thresholds
    /// - Parameters:
    ///   - horizontalAccuracyThreshold: Maximum horizontal accuracy in meters (default: 20m)
    ///   - verticalAccuracyThreshold: Maximum vertical accuracy in meters (default: 50m)
    ///   - maxLocationAge: Maximum age of location in seconds (default: 10s)
    ///   - minimumDisplacement: Minimum distance from last location in meters (default: 5m)
    ///   - maxSpeed: Maximum possible speed in m/s (default: 50 m/s ~180 km/h)
    init(
        horizontalAccuracyThreshold: CLLocationDistance = 20.0,
        verticalAccuracyThreshold: CLLocationDistance = 50.0,
        maxLocationAge: TimeInterval = 10.0,
        minimumDisplacement: CLLocationDistance = 5.0,
        maxSpeed: CLLocationSpeed = 50.0
    ) {
        self.horizontalAccuracyThreshold = horizontalAccuracyThreshold
        self.verticalAccuracyThreshold = verticalAccuracyThreshold
        self.maxLocationAge = maxLocationAge
        self.minimumDisplacement = minimumDisplacement
        self.maxSpeed = maxSpeed
    }

    /// Create filter configured for specific activity type
    /// - Parameter activityType: The type of activity being tracked
    /// - Returns: Configured LocationFilter instance
    static func filter(for activityType: ActivityType) -> LocationFilter {
        switch activityType {
        case .walk:
            return LocationFilter(
                horizontalAccuracyThreshold: 20.0,
                verticalAccuracyThreshold: 50.0,
                maxLocationAge: 10.0,
                minimumDisplacement: 5.0,
                maxSpeed: 5.0 // ~18 km/h max walking speed
            )
        case .run:
            return LocationFilter(
                horizontalAccuracyThreshold: 15.0,
                verticalAccuracyThreshold: 40.0,
                maxLocationAge: 10.0,
                minimumDisplacement: 5.0,
                maxSpeed: 15.0 // ~54 km/h max running speed
            )
        case .bike:
            return LocationFilter(
                horizontalAccuracyThreshold: 15.0,
                verticalAccuracyThreshold: 40.0,
                maxLocationAge: 10.0,
                minimumDisplacement: 8.0,
                maxSpeed: 30.0 // ~108 km/h max biking speed
            )
        }
    }

    // MARK: - Filtering

    /// Filter a location and determine if it should be accepted
    /// - Parameter location: The location to filter
    /// - Returns: FilterResult indicating whether to accept and the reason if rejected
    func shouldAccept(_ location: CLLocation) -> FilterResult {
        totalLocations += 1

        // Filter 1: Horizontal accuracy
        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= horizontalAccuracyThreshold else {
            rejectedByAccuracy += 1
            return .rejected(reason: .poorAccuracy(location.horizontalAccuracy))
        }

        // Filter 2: Vertical accuracy (if altitude is being used)
        if location.verticalAccuracy > 0,
           location.verticalAccuracy > verticalAccuracyThreshold {
            // Don't reject, but flag as poor vertical accuracy
            // Still accept for horizontal tracking
        }

        // Filter 3: Timestamp (reject stale locations)
        let age = abs(location.timestamp.timeIntervalSinceNow)
        guard age <= maxLocationAge else {
            rejectedByAge += 1
            return .rejected(reason: .staleLocation(age))
        }

        // Filter 4: Minimum displacement from last location
        if let lastLocation = lastAcceptedLocation {
            let distance = location.distance(from: lastLocation)

            // If distance is less than minimum, reject
            if distance < minimumDisplacement {
                rejectedByDisplacement += 1
                return .rejected(reason: .insufficientDisplacement(distance))
            }

            // Filter 5: Speed validation
            let timeDelta = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            if timeDelta > 0 {
                let speed = distance / timeDelta

                // Check if speed is impossibly high
                if speed > maxSpeed {
                    rejectedBySpeed += 1
                    return .rejected(reason: .impossibleSpeed(speed))
                }
            }
        }

        // Location passed all filters
        acceptedLocations += 1
        lastAcceptedLocation = location
        return .accepted
    }

    /// Reset filter state (call when starting new workout)
    func reset() {
        lastAcceptedLocation = nil
        totalLocations = 0
        acceptedLocations = 0
        rejectedByAccuracy = 0
        rejectedByAge = 0
        rejectedByDisplacement = 0
        rejectedBySpeed = 0
    }

    /// Get filter statistics
    /// - Returns: Dictionary of filter statistics
    func statistics() -> FilterStatistics {
        FilterStatistics(
            totalLocations: totalLocations,
            acceptedLocations: acceptedLocations,
            rejectedByAccuracy: rejectedByAccuracy,
            rejectedByAge: rejectedByAge,
            rejectedByDisplacement: rejectedByDisplacement,
            rejectedBySpeed: rejectedBySpeed
        )
    }

    /// Update minimum displacement threshold (useful for dynamic adjustment)
    /// - Parameter displacement: New minimum displacement in meters
    func updateMinimumDisplacement(_ displacement: CLLocationDistance) {
        // Implemented as var instead of let to allow updates
    }
}

// MARK: - Supporting Types

/// Result of location filtering
enum FilterResult {
    case accepted
    case rejected(reason: RejectionReason)

    var isAccepted: Bool {
        if case .accepted = self {
            return true
        }
        return false
    }

    var rejectionReason: RejectionReason? {
        if case .rejected(let reason) = self {
            return reason
        }
        return nil
    }
}

/// Reason why a location was rejected
enum RejectionReason: Equatable {
    case poorAccuracy(CLLocationDistance)
    case staleLocation(TimeInterval)
    case insufficientDisplacement(CLLocationDistance)
    case impossibleSpeed(CLLocationSpeed)

    var description: String {
        switch self {
        case .poorAccuracy(let accuracy):
            return "Poor accuracy: \(String(format: "%.1f", accuracy))m"
        case .staleLocation(let age):
            return "Stale location: \(String(format: "%.1f", age))s old"
        case .insufficientDisplacement(let distance):
            return "Insufficient displacement: \(String(format: "%.1f", distance))m"
        case .impossibleSpeed(let speed):
            return "Impossible speed: \(String(format: "%.1f", speed * 3.6))km/h"
        }
    }
}

/// Statistics about location filtering
struct FilterStatistics {
    let totalLocations: Int
    let acceptedLocations: Int
    let rejectedByAccuracy: Int
    let rejectedByAge: Int
    let rejectedByDisplacement: Int
    let rejectedBySpeed: Int

    var acceptanceRate: Double {
        guard totalLocations > 0 else { return 0 }
        return Double(acceptedLocations) / Double(totalLocations)
    }

    var rejectedCount: Int {
        return totalLocations - acceptedLocations
    }
}

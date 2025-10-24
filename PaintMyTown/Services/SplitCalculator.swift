//
//  SplitCalculator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreLocation

/// Calculates splits (per km or mile segments) during a workout
class SplitCalculator {
    // MARK: - Properties

    /// Distance unit for split calculation
    private let distanceUnit: DistanceUnit

    /// Distance threshold for each split in meters
    private let splitThreshold: Double

    /// Current split being tracked
    private var currentSplit: SplitData?

    /// Completed splits
    private(set) var completedSplits: [Split] = []

    /// Total distance accumulated
    private var totalDistance: Double = 0.0

    /// Last location for distance calculation
    private var lastLocation: CLLocation?

    /// Last elevation for elevation gain calculation
    private var lastElevation: Double?

    // MARK: - Initialization

    init(distanceUnit: DistanceUnit = .kilometers) {
        self.distanceUnit = distanceUnit
        self.splitThreshold = distanceUnit.metersPerUnit

        // Initialize first split
        self.currentSplit = SplitData(
            startTime: Date(),
            startDistance: 0.0,
            targetDistance: splitThreshold
        )
    }

    // MARK: - Public Methods

    /// Process a new location and update splits
    /// - Parameter location: The new GPS location
    /// - Returns: A newly completed split, if any
    func processLocation(_ location: CLLocation) -> Split? {
        // Calculate distance from last location
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            totalDistance += distance

            // Update current split distance
            currentSplit?.distance += distance

            // Update elevation
            updateElevation(location.altitude)
        }

        lastLocation = location

        // Check if we've completed a split
        guard let split = currentSplit, split.distance >= splitThreshold else {
            return nil
        }

        // Complete the split
        return completeSplit()
    }

    /// Reset the calculator
    func reset() {
        currentSplit = SplitData(
            startTime: Date(),
            startDistance: 0.0,
            targetDistance: splitThreshold
        )
        completedSplits = []
        totalDistance = 0.0
        lastLocation = nil
        lastElevation = nil
    }

    /// Get the current split progress (0.0 to 1.0)
    var currentSplitProgress: Double {
        guard let split = currentSplit else { return 0.0 }
        return min(split.distance / splitThreshold, 1.0)
    }

    /// Distance remaining in current split (meters)
    var distanceRemainingInSplit: Double {
        guard let split = currentSplit else { return splitThreshold }
        return max(splitThreshold - split.distance, 0.0)
    }

    // MARK: - Private Methods

    private func completeSplit() -> Split {
        guard let splitData = currentSplit else {
            fatalError("No current split to complete")
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(splitData.startTime)
        let pace = duration / (splitThreshold / 1000.0) // sec/km or sec/mi

        let split = Split(
            distance: splitThreshold,
            duration: duration,
            pace: pace,
            elevationGain: splitData.elevationGain
        )

        completedSplits.append(split)

        // Start new split
        currentSplit = SplitData(
            startTime: endTime,
            startDistance: totalDistance,
            targetDistance: totalDistance + splitThreshold
        )

        return split
    }

    private func updateElevation(_ altitude: Double) {
        guard let lastElev = lastElevation else {
            lastElevation = altitude
            return
        }

        // Filter out GPS noise - only count changes > 3 meters
        let elevationChange = altitude - lastElev
        if elevationChange > 3.0 {
            currentSplit?.elevationGain += elevationChange
            lastElevation = altitude
        } else if elevationChange < -3.0 {
            // Also update reference for significant drops
            lastElevation = altitude
        }
    }
}

// MARK: - Supporting Types

private struct SplitData {
    let startTime: Date
    let startDistance: Double
    let targetDistance: Double
    var distance: Double = 0.0
    var elevationGain: Double = 0.0
}

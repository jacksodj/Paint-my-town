//
//  WorkoutMetrics.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Real-time workout metrics calculated during an active workout
struct WorkoutMetrics: Equatable, Codable {
    /// Total distance traveled in meters
    var distance: Double = 0.0

    /// Total elapsed time in seconds (including pauses)
    var elapsedTime: TimeInterval = 0.0

    /// Total moving time in seconds (excluding pauses)
    var movingTime: TimeInterval = 0.0

    /// Current pace in seconds per kilometer (last 30 seconds or 200m)
    var currentPace: Double?

    /// Average pace in seconds per kilometer (based on moving time)
    var averagePace: Double {
        guard movingTime > 0, distance > 0 else { return 0 }
        let distanceInKm = distance / 1000.0
        return movingTime / distanceInKm
    }

    /// Current speed in meters per second
    var currentSpeed: Double?

    /// Average speed in meters per second
    var averageSpeed: Double {
        guard movingTime > 0 else { return 0 }
        return distance / movingTime
    }

    /// Total elevation gain in meters
    var elevationGain: Double = 0.0

    /// Total elevation loss in meters
    var elevationLoss: Double = 0.0

    /// Number of splits completed
    var splitCount: Int = 0

    /// Number of location points recorded
    var locationCount: Int = 0

    /// Formatted distance string
    func formattedDistance(unit: DistanceUnit) -> String {
        let convertedDistance = distance / unit.metersPerUnit
        return String(format: "%.2f %@", convertedDistance, unit.abbreviation)
    }

    /// Formatted elapsed time string (HH:MM:SS)
    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }

    /// Formatted moving time string (HH:MM:SS)
    var formattedMovingTime: String {
        formatTime(movingTime)
    }

    /// Formatted current pace string
    func formattedCurrentPace(unit: DistanceUnit) -> String? {
        guard let pace = currentPace else { return nil }
        return formatPace(pace, unit: unit)
    }

    /// Formatted average pace string
    func formattedAveragePace(unit: DistanceUnit) -> String {
        formatPace(averagePace, unit: unit)
    }

    // MARK: - Private Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatPace(_ pace: Double, unit: DistanceUnit) -> String {
        let paceValue = unit == .kilometers ? pace : pace * 1.60934
        let minutes = Int(paceValue / 60)
        let seconds = Int(paceValue.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /%@", minutes, seconds, unit.abbreviation)
    }
}

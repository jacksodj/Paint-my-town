//
//  Activity.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Domain model representing a completed activity/workout
struct Activity: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let startDate: Date
    let endDate: Date
    let distance: Double // meters
    let duration: Double // seconds
    let elevationGain: Double // meters
    let elevationLoss: Double // meters
    let averagePace: Double // seconds per km
    let notes: String?
    let locations: [LocationSample]
    let splits: [Split]

    init(
        id: UUID = UUID(),
        type: ActivityType,
        startDate: Date,
        endDate: Date,
        distance: Double,
        duration: Double,
        elevationGain: Double,
        elevationLoss: Double,
        averagePace: Double,
        notes: String? = nil,
        locations: [LocationSample] = [],
        splits: [Split] = []
    ) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.distance = distance
        self.duration = duration
        self.elevationGain = elevationGain
        self.elevationLoss = elevationLoss
        self.averagePace = averagePace
        self.notes = notes
        self.locations = locations
        self.splits = splits
    }

    /// Distance in kilometers
    var distanceInKilometers: Double {
        distance / 1000.0
    }

    /// Distance in miles
    var distanceInMiles: Double {
        distance / 1609.34
    }

    /// Formatted distance string
    func formattedDistance(unit: DistanceUnit) -> String {
        let value = unit == .kilometers ? distanceInKilometers : distanceInMiles
        return String(format: "%.2f %@", value, unit.abbreviation)
    }

    /// Formatted duration string (HH:MM:SS)
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted pace string
    func formattedPace(unit: DistanceUnit) -> String {
        let paceValue = unit == .kilometers ? averagePace : averagePace * 1.60934
        let minutes = Int(paceValue / 60)
        let seconds = Int(paceValue.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /%@", minutes, seconds, unit.abbreviation)
    }
}

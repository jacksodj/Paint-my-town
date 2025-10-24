//
//  Split.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Domain model representing a split (per km/mi segment)
struct Split: Identifiable, Codable {
    let id: UUID
    let distance: Double // meters
    let duration: Double // seconds
    let pace: Double // seconds per km
    let elevationGain: Double // meters

    init(
        id: UUID = UUID(),
        distance: Double,
        duration: Double,
        pace: Double,
        elevationGain: Double
    ) {
        self.id = id
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.elevationGain = elevationGain
    }

    /// Formatted pace string (e.g., "5:23 /km")
    func formattedPace(unit: DistanceUnit) -> String {
        let paceValue = unit == .kilometers ? pace : pace * 1.60934
        let minutes = Int(paceValue / 60)
        let seconds = Int(paceValue.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /%@", minutes, seconds, unit.abbreviation)
    }
}

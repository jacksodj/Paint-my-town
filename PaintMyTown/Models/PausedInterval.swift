//
//  PausedInterval.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Represents a time interval when a workout was paused
struct PausedInterval: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    var endTime: Date?

    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Duration of the pause in seconds
    var duration: TimeInterval {
        guard let endTime = endTime else {
            // If pause is still ongoing, calculate from start time to now
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }

    /// Whether this pause interval is currently active (not yet resumed)
    var isActive: Bool {
        endTime == nil
    }

    /// Complete the pause interval
    mutating func complete() {
        endTime = Date()
    }
}

//
//  WorkoutState.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Represents the current state of a workout
enum WorkoutState: String, Codable, Equatable {
    /// Workout is actively recording
    case recording

    /// Workout is paused (manually or auto-paused)
    case paused

    /// Workout has been stopped and is ready to be saved or discarded
    case stopped

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .recording:
            return "Recording"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        }
    }

    /// Whether the workout is actively collecting data
    var isActive: Bool {
        self == .recording
    }

    /// Whether the workout can be resumed
    var canResume: Bool {
        self == .paused
    }

    /// Whether the workout can be paused
    var canPause: Bool {
        self == .recording
    }

    /// Whether the workout can be stopped/ended
    var canStop: Bool {
        self == .recording || self == .paused
    }
}

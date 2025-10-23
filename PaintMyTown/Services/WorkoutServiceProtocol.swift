//
//  WorkoutServiceProtocol.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import Combine

/// Protocol defining workout management capabilities
protocol WorkoutServiceProtocol: ServiceProtocol {
    /// Currently active workout (nil if no workout in progress)
    var activeWorkout: ActiveWorkout? { get }

    /// Publisher that emits active workout changes
    var activeWorkoutPublisher: AnyPublisher<ActiveWorkout?, Never> { get }

    /// Publisher that emits real-time workout metrics
    var metricsPublisher: AnyPublisher<WorkoutMetrics, Never> { get }

    /// Start a new workout
    /// - Parameter type: The type of activity to start
    /// - Returns: The newly created active workout
    /// - Throws: WorkoutServiceError if a workout is already active or location is unavailable
    func startWorkout(type: ActivityType) throws -> ActiveWorkout

    /// Pause the current workout
    /// - Throws: WorkoutServiceError if no workout is active
    func pauseWorkout() throws

    /// Resume the paused workout
    /// - Throws: WorkoutServiceError if no workout is paused
    func resumeWorkout() throws

    /// End the current workout and return the completed activity
    /// - Returns: The completed Activity ready to be saved
    /// - Throws: WorkoutServiceError if no workout is active
    func endWorkout() throws -> Activity

    /// Cancel the current workout without saving
    /// - Throws: WorkoutServiceError if no workout is active
    func cancelWorkout() throws
}

/// Errors that can occur in the workout service
enum WorkoutServiceError: Error, LocalizedError {
    case noActiveWorkout
    case workoutAlreadyActive
    case locationServiceUnavailable
    case invalidWorkoutState(String)

    var errorDescription: String? {
        switch self {
        case .noActiveWorkout:
            return "No active workout to perform this action on."
        case .workoutAlreadyActive:
            return "A workout is already in progress. End the current workout before starting a new one."
        case .locationServiceUnavailable:
            return "Location service is not available. Please enable location permissions."
        case .invalidWorkoutState(let message):
            return "Invalid workout state: \(message)"
        }
    }
}

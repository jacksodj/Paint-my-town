//
//  WorkoutPersistenceServiceProtocol.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Protocol defining the contract for workout persistence operations
protocol WorkoutPersistenceServiceProtocol {
    /// Save a completed workout to Core Data
    /// - Parameters:
    ///   - activeWorkout: The active workout to save
    ///   - notes: Optional notes to attach to the workout
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: The saved Activity with persisted ID
    func saveWorkout(
        _ activeWorkout: ActiveWorkout,
        notes: String?,
        progressHandler: WorkoutPersistenceService.ProgressHandler?
    ) async throws -> Activity
}

/// Protocol defining the contract for workout recovery operations
protocol RecoveryServiceProtocol {
    /// Save the active workout state to disk
    func saveWorkoutState(_ workout: ActiveWorkout) async throws

    /// Load the active workout state from disk
    func loadWorkoutState() async throws -> Activity?

    /// Clear the saved workout state
    func clearWorkoutState() async

    /// Check if recovery data exists
    func hasRecoveryData() -> Bool

    /// Get recovery data info
    func getRecoveryInfo() async -> RecoveryInfo?

    /// Start periodic auto-save
    func startAutoSave(for workout: ActiveWorkout)

    /// Stop periodic auto-save
    func stopAutoSave()

    /// Save workout to file system as emergency backup
    func saveToFileSystemBackup(_ activity: Activity) async throws
}

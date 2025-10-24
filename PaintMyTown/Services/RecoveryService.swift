//
//  RecoveryService.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Service responsible for crash recovery of active workouts
/// Persists workout state to file system and handles recovery on app launch
class RecoveryService: RecoveryServiceProtocol {
    // MARK: - Properties

    private let fileManager = FileManager.default
    private let logger = Logger(category: .general)

    /// Directory for storing recovery files
    private var recoveryDirectory: URL {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("WorkoutRecovery", isDirectory: true)
    }

    /// File path for active workout state
    private var activeWorkoutFile: URL {
        recoveryDirectory.appendingPathComponent("active_workout.json")
    }

    /// File path for backup workout state
    private var backupWorkoutFile: URL {
        recoveryDirectory.appendingPathComponent("active_workout_backup.json")
    }

    /// How often to save workout state during recording (in seconds)
    private let autoSaveInterval: TimeInterval = 10.0

    /// Timer for periodic saves
    private var autoSaveTimer: Timer?

    // MARK: - Initialization

    init() {
        createRecoveryDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    /// Create recovery directory if it doesn't exist
    private func createRecoveryDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(
                at: recoveryDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            logger.error("Failed to create recovery directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Save Workout State

    /// Save the active workout state to disk
    /// - Parameter workout: The active workout to save
    func saveWorkoutState(_ workout: ActiveWorkout) async throws {
        do {
            // Convert to Activity for serialization
            let activity = workout.toActivity()

            // Encode workout to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activity)

            // Save to primary file
            try data.write(to: activeWorkoutFile, options: [.atomic])

            // Also save to backup (for redundancy)
            try? data.write(to: backupWorkoutFile, options: [.atomic])

            logger.info("Saved workout state: \(workout.id) - \(workout.locations.count) locations")

        } catch {
            logger.error("Failed to save workout state: \(error.localizedDescription)")
            throw WorkoutPersistenceError.recoverySerializationFailed(underlying: error)
        }
    }

    /// Save workout state synchronously (for timer-based saves)
    func saveWorkoutStateSync(_ workout: ActiveWorkout) {
        Task {
            try? await saveWorkoutState(workout)
        }
    }

    // MARK: - Load Workout State

    /// Load the active workout state from disk
    /// - Returns: The recovered activity, or nil if no recovery data exists
    func loadWorkoutState() async throws -> Activity? {
        var fileToLoad = activeWorkoutFile

        // Check if primary file exists
        if !fileManager.fileExists(atPath: fileToLoad.path) {
            // Try backup file
            if fileManager.fileExists(atPath: backupWorkoutFile.path) {
                fileToLoad = backupWorkoutFile
                logger.warning("Primary recovery file not found, using backup")
            } else {
                // No recovery data
                return nil
            }
        }

        do {
            // Read file
            let data = try Data(contentsOf: fileToLoad)

            // Decode workout
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let activity = try decoder.decode(Activity.self, from: data)

            logger.info("Loaded workout state: \(activity.id) - \(activity.locations.count) locations")

            // Validate recovery data
            try validateRecoveryData(activity)

            return activity

        } catch let error as DecodingError {
            logger.error("Failed to decode workout state: \(error)")
            throw WorkoutPersistenceError.recoveryDeserializationFailed(underlying: error)
        } catch let error as WorkoutPersistenceError {
            throw error
        } catch {
            logger.error("Failed to load workout state: \(error.localizedDescription)")
            throw WorkoutPersistenceError.recoveryDeserializationFailed(underlying: error)
        }
    }

    // MARK: - Clear Workout State

    /// Clear the saved workout state (called after successful save or discard)
    func clearWorkoutState() async {
        do {
            // Remove primary file
            if fileManager.fileExists(atPath: activeWorkoutFile.path) {
                try fileManager.removeItem(at: activeWorkoutFile)
            }

            // Remove backup file
            if fileManager.fileExists(atPath: backupWorkoutFile.path) {
                try fileManager.removeItem(at: backupWorkoutFile)
            }

            logger.info("Cleared workout recovery state")

        } catch {
            logger.error("Failed to clear workout state: \(error.localizedDescription)")
        }
    }

    // MARK: - Check for Recovery Data

    /// Check if there is recovery data available
    /// - Returns: True if recovery data exists, false otherwise
    func hasRecoveryData() -> Bool {
        return fileManager.fileExists(atPath: activeWorkoutFile.path) ||
               fileManager.fileExists(atPath: backupWorkoutFile.path)
    }

    /// Get recovery data info (for displaying to user)
    func getRecoveryInfo() async -> RecoveryInfo? {
        guard hasRecoveryData() else { return nil }

        do {
            if let workout = try await loadWorkoutState() {
                return RecoveryInfo(
                    workoutID: workout.id,
                    activityType: workout.type,
                    startDate: workout.startDate,
                    distance: workout.distance,
                    duration: workout.duration,
                    locationCount: workout.locations.count,
                    splitCount: workout.splits.count
                )
            }
        } catch {
            logger.error("Failed to load recovery info: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Validate Recovery Data

    /// Validate that recovery data is not corrupted
    private func validateRecoveryData(_ workout: Activity) throws {
        // Check if workout is too old (more than 7 days)
        let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        let age = Date().timeIntervalSince(workout.startDate)

        if age > maxAge {
            throw WorkoutPersistenceError.recoveryDataCorrupted
        }

        // Check if workout has some minimum data
        if workout.locations.isEmpty {
            throw WorkoutPersistenceError.recoveryDataCorrupted
        }

        // Check for data integrity
        if workout.distance < 0 || workout.duration < 0 {
            throw WorkoutPersistenceError.recoveryDataCorrupted
        }
    }

    // MARK: - Auto-Save Management

    /// Start periodic auto-save for the active workout
    /// - Parameter workout: The workout to auto-save
    func startAutoSave(for workout: ActiveWorkout) {
        stopAutoSave() // Stop any existing timer

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.saveWorkoutStateSync(workout)
        }

        logger.info("Started auto-save timer (interval: \(self.autoSaveInterval)s)")
    }

    /// Stop periodic auto-save
    func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        logger.info("Stopped auto-save timer")
    }

    // MARK: - Backup to File System (Emergency Fallback)

    /// Save workout to file system as emergency backup
    /// Used when Core Data save fails
    func saveToFileSystemBackup(_ activity: Activity) async throws {
        let backupDir = recoveryDirectory.appendingPathComponent("Backups", isDirectory: true)

        // Create backups directory
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)

        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: activity.startDate)
        let filename = "workout_backup_\(dateString).json"
        let fileURL = backupDir.appendingPathComponent(filename)

        // Encode activity
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(activity)

        // Write to file
        try data.write(to: fileURL, options: .atomic)

        logger.info("Saved workout to file system backup: \(filename)")
    }

    /// List all backup files
    func listBackupFiles() -> [URL] {
        let backupDir = recoveryDirectory.appendingPathComponent("Backups", isDirectory: true)

        guard let files = try? fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 > date2
        }
    }

    /// Load activity from backup file
    func loadFromBackup(url: URL) async throws -> Activity {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activity = try decoder.decode(Activity.self, from: data)

        logger.info("Loaded activity from backup: \(url.lastPathComponent)")

        return activity
    }

    /// Delete old backup files (keep only last 10)
    func cleanOldBackups() {
        let backups = listBackupFiles()
        let maxBackups = 10

        if backups.count > maxBackups {
            let toDelete = backups.dropFirst(maxBackups)
            for file in toDelete {
                try? fileManager.removeItem(at: file)
                logger.info("Deleted old backup: \(file.lastPathComponent)")
            }
        }
    }
}

// MARK: - Recovery Info

/// Information about recoverable workout
struct RecoveryInfo {
    let workoutID: UUID
    let activityType: ActivityType
    let startDate: Date
    let distance: Double
    let duration: Double
    let locationCount: Int
    let splitCount: Int

    /// Formatted description for display
    var description: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        let distanceKm = distance / 1000.0
        let durationMin = Int(duration / 60)

        return """
        \(activityType.displayName) workout from \(dateFormatter.string(from: startDate))
        Distance: \(String(format: "%.2f", distanceKm)) km
        Duration: \(durationMin) minutes
        GPS points: \(locationCount)
        """
    }

    /// Age of the workout
    var age: TimeInterval {
        Date().timeIntervalSince(startDate)
    }

    /// Is the workout fresh (less than 1 hour old)
    var isFresh: Bool {
        age < 3600 // 1 hour
    }
}

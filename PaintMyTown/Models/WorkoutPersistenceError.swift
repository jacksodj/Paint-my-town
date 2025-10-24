//
//  WorkoutPersistenceError.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Errors that can occur during workout persistence operations
enum WorkoutPersistenceError: Error, LocalizedError {
    // MARK: - Validation Errors

    case insufficientData(reason: String)
    case invalidWorkoutData(reason: String)
    case missingRequiredData(field: String)

    // MARK: - Save Errors

    case saveFailed(underlying: Error)
    case batchInsertFailed(itemCount: Int, underlying: Error)
    case partialSaveFailure(savedItems: Int, totalItems: Int, underlying: Error)
    case contextSaveFailed(underlying: Error)

    // MARK: - Storage Errors

    case storageQuotaExceeded
    case diskSpaceInsufficient(requiredBytes: Int64)
    case fileSystemError(underlying: Error)

    // MARK: - Recovery Errors

    case recoveryDataCorrupted
    case recoveryDataNotFound
    case recoveryDeserializationFailed(underlying: Error)
    case recoverySerializationFailed(underlying: Error)

    // MARK: - Transaction Errors

    case transactionFailed(underlying: Error)
    case rollbackFailed(underlying: Error)
    case concurrentModification

    // MARK: - Timeout Errors

    case saveTimeout
    case operationCancelled

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        // Validation Errors
        case .insufficientData(let reason):
            return "Insufficient data to save workout: \(reason)"
        case .invalidWorkoutData(let reason):
            return "Invalid workout data: \(reason)"
        case .missingRequiredData(let field):
            return "Missing required workout data: \(field)"

        // Save Errors
        case .saveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        case .batchInsertFailed(let count, let error):
            return "Failed to insert \(count) location samples: \(error.localizedDescription)"
        case .partialSaveFailure(let saved, let total, let error):
            return "Only \(saved) of \(total) items were saved: \(error.localizedDescription)"
        case .contextSaveFailed(let error):
            return "Failed to save database context: \(error.localizedDescription)"

        // Storage Errors
        case .storageQuotaExceeded:
            return "Storage quota exceeded. Free up space and try again."
        case .diskSpaceInsufficient(let bytes):
            let mb = Double(bytes) / 1_048_576.0
            return "Insufficient disk space. Need at least \(String(format: "%.1f", mb)) MB."
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"

        // Recovery Errors
        case .recoveryDataCorrupted:
            return "Recovery data is corrupted and cannot be restored."
        case .recoveryDataNotFound:
            return "No recovery data found."
        case .recoveryDeserializationFailed(let error):
            return "Failed to load recovery data: \(error.localizedDescription)"
        case .recoverySerializationFailed(let error):
            return "Failed to save recovery data: \(error.localizedDescription)"

        // Transaction Errors
        case .transactionFailed(let error):
            return "Database transaction failed: \(error.localizedDescription)"
        case .rollbackFailed(let error):
            return "Failed to rollback transaction: \(error.localizedDescription)"
        case .concurrentModification:
            return "Data was modified by another operation. Please try again."

        // Timeout Errors
        case .saveTimeout:
            return "Save operation timed out. The workout is too large."
        case .operationCancelled:
            return "Save operation was cancelled."
        }
    }

    var failureReason: String? {
        switch self {
        case .insufficientData:
            return "The workout doesn't have enough location data to be saved."
        case .storageQuotaExceeded, .diskSpaceInsufficient:
            return "Your device is running low on storage."
        case .recoveryDataCorrupted:
            return "The temporary workout data was corrupted."
        case .saveTimeout:
            return "The workout has too many location samples to save quickly."
        case .partialSaveFailure:
            return "Some workout data was saved, but the operation didn't complete."
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientData:
            return "Record for at least 30 seconds and cover some distance before saving."
        case .storageQuotaExceeded, .diskSpaceInsufficient:
            return "Delete some files or apps to free up storage space, then try again."
        case .recoveryDataCorrupted:
            return "The workout data cannot be recovered. You may need to discard it."
        case .saveTimeout:
            return "Try saving again. If the problem persists, the workout may be too long."
        case .partialSaveFailure:
            return "Try saving again. Your data has been backed up to temporary storage."
        case .saveFailed, .contextSaveFailed, .transactionFailed:
            return "Try restarting the app. If the problem persists, contact support."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Validation Helpers

extension WorkoutPersistenceError {
    /// Validate an ActiveWorkout before saving
    static func validate(_ workout: ActiveWorkout) throws {
        // Check if workout has sufficient data
        let hasSufficientData = workout.locations.count >= 2 && workout.metrics.distance >= 10.0
        guard hasSufficientData else {
            throw WorkoutPersistenceError.insufficientData(
                reason: "Workout has only \(workout.locations.count) locations and \(String(format: "%.1f", workout.metrics.distance))m distance"
            )
        }

        // Check if workout has locations
        guard !workout.locations.isEmpty else {
            throw WorkoutPersistenceError.missingRequiredData(field: "locations")
        }

        // Check if workout has been stopped
        guard workout.state == .stopped else {
            throw WorkoutPersistenceError.invalidWorkoutData(reason: "Workout has not been stopped")
        }

        guard workout.metrics.movingTime > 0 else {
            throw WorkoutPersistenceError.invalidWorkoutData(reason: "Workout duration must be greater than 0")
        }

        // Check for unreasonably large workouts (more than 100,000 location samples)
        guard workout.locations.count <= 100_000 else {
            throw WorkoutPersistenceError.invalidWorkoutData(
                reason: "Workout has too many location samples (\(workout.locations.count))"
            )
        }
    }
}

// MARK: - Error Severity

extension WorkoutPersistenceError {
    /// Severity level for logging and error handling
    enum Severity {
        case warning // Recoverable, user should retry
        case error // Serious, may need user intervention
        case critical // Data loss possible, requires immediate attention
    }

    var severity: Severity {
        switch self {
        case .insufficientData, .invalidWorkoutData, .missingRequiredData:
            return .warning
        case .operationCancelled:
            return .warning
        case .saveFailed, .batchInsertFailed, .contextSaveFailed:
            return .error
        case .partialSaveFailure, .transactionFailed, .rollbackFailed:
            return .critical
        case .storageQuotaExceeded, .diskSpaceInsufficient:
            return .error
        case .recoveryDataCorrupted, .recoveryDataNotFound:
            return .error
        case .saveTimeout, .concurrentModification:
            return .error
        default:
            return .error
        }
    }

    /// Whether the operation should be retried
    var shouldRetry: Bool {
        switch self {
        case .insufficientData, .invalidWorkoutData, .missingRequiredData:
            return false
        case .operationCancelled:
            return false
        case .storageQuotaExceeded, .diskSpaceInsufficient:
            return false
        case .recoveryDataCorrupted:
            return false
        case .concurrentModification:
            return true
        case .saveTimeout:
            return true
        case .saveFailed, .batchInsertFailed, .contextSaveFailed, .transactionFailed:
            return true
        default:
            return false
        }
    }
}

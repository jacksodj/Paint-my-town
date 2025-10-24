//
//  AppError.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Application-wide error types with user-friendly messages
enum AppError: LocalizedError, Identifiable, Equatable {
    // MARK: - Location Errors

    case locationPermissionDenied
    case locationPermissionRestricted
    case locationUnavailable
    case locationAccuracyTooLow
    case locationServicesFailed(underlying: Error)

    // MARK: - Database Errors

    case databaseReadFailed(underlying: Error)
    case databaseWriteFailed(underlying: Error)
    case databaseDeleteFailed(underlying: Error)
    case databaseCorrupted
    case recordNotFound

    // MARK: - Permission Errors

    case permissionNotDetermined
    case permissionDenied(type: PermissionType)
    case permissionRestricted(type: PermissionType)

    // MARK: - Workout Errors

    case workoutAlreadyActive
    case noActiveWorkout
    case workoutSaveFailed(underlying: Error)
    case insufficientDataForWorkout

    // MARK: - HealthKit Errors

    case healthKitNotAvailable
    case healthKitPermissionDenied
    case healthKitWriteFailed(underlying: Error)
    case healthKitReadFailed(underlying: Error)

    // MARK: - Network Errors

    case networkUnavailable
    case networkTimeout
    case networkFailed(underlying: Error)

    // MARK: - Import/Export Errors

    case exportFailed(underlying: Error)
    case importFailed(underlying: Error)
    case invalidFileFormat
    case fileNotFound

    // MARK: - General Errors

    case unknown(underlying: Error)
    case invalidInput(message: String)
    case operationCancelled

    // MARK: - Identifiable

    var id: String {
        errorDescription ?? "unknown"
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        // Location Errors
        case .locationPermissionDenied:
            return "Location permission denied. Please enable location access in Settings to record your activities."
        case .locationPermissionRestricted:
            return "Location access is restricted on this device."
        case .locationUnavailable:
            return "Location is currently unavailable. Please check your device settings."
        case .locationAccuracyTooLow:
            return "GPS signal is too weak. Move to an open area for better accuracy."
        case .locationServicesFailed(let error):
            return "Location services failed: \(error.localizedDescription)"

        // Database Errors
        case .databaseReadFailed(let error):
            return "Failed to read data from database: \(error.localizedDescription)"
        case .databaseWriteFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .databaseDeleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .databaseCorrupted:
            return "Database is corrupted. Please contact support."
        case .recordNotFound:
            return "The requested record was not found."

        // Permission Errors
        case .permissionNotDetermined:
            return "Permission has not been requested yet."
        case .permissionDenied(let type):
            return "\(type.displayName) permission denied. Please enable it in Settings."
        case .permissionRestricted(let type):
            return "\(type.displayName) access is restricted on this device."

        // Workout Errors
        case .workoutAlreadyActive:
            return "A workout is already in progress. End the current workout before starting a new one."
        case .noActiveWorkout:
            return "No active workout to pause or stop."
        case .workoutSaveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        case .insufficientDataForWorkout:
            return "Not enough data to save this workout. Try recording for a longer duration."

        // HealthKit Errors
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device."
        case .healthKitPermissionDenied:
            return "HealthKit permission denied. Enable it in Settings to sync your workouts."
        case .healthKitWriteFailed(let error):
            return "Failed to save workout to Health: \(error.localizedDescription)"
        case .healthKitReadFailed(let error):
            return "Failed to read from Health: \(error.localizedDescription)"

        // Network Errors
        case .networkUnavailable:
            return "No internet connection available."
        case .networkTimeout:
            return "The request timed out. Please try again."
        case .networkFailed(let error):
            return "Network error: \(error.localizedDescription)"

        // Import/Export Errors
        case .exportFailed(let error):
            return "Failed to export: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import: \(error.localizedDescription)"
        case .invalidFileFormat:
            return "Invalid file format. Please select a valid GPX file."
        case .fileNotFound:
            return "File not found."

        // General Errors
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        case .invalidInput(let message):
            return message
        case .operationCancelled:
            return "Operation was cancelled."
        }
    }

    var failureReason: String? {
        switch self {
        case .locationPermissionDenied, .locationPermissionRestricted:
            return "Location access is required to track your activities."
        case .databaseCorrupted:
            return "The app's database may have been corrupted."
        case .workoutAlreadyActive:
            return "Only one workout can be recorded at a time."
        case .healthKitNotAvailable:
            return "HealthKit is only available on iPhone and Apple Watch."
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .locationPermissionDenied, .permissionDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        case .locationAccuracyTooLow:
            return "Move to an area with a clear view of the sky for better GPS signal."
        case .databaseCorrupted:
            return "Try restarting the app. If the problem persists, you may need to reinstall."
        case .workoutAlreadyActive:
            return "Tap the 'Stop' button to end the current workout first."
        case .healthKitPermissionDenied:
            return "Go to Settings > Health > Data Access & Devices to enable access."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .insufficientDataForWorkout:
            return "Record for at least 30 seconds and cover some distance."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Supporting Types

/// Permission types used in the app
enum PermissionType {
    case location
    case locationAlways
    case motion
    case healthKit

    var displayName: String {
        switch self {
        case .location: return "Location"
        case .locationAlways: return "Background Location"
        case .motion: return "Motion & Fitness"
        case .healthKit: return "Health"
        }
    }

    var icon: String {
        switch self {
        case .location, .locationAlways: return "location.fill"
        case .motion: return "figure.walk"
        case .healthKit: return "heart.fill"
        }
    }

    var description: String {
        switch self {
        case .location:
            return "Required to track your location during workouts"
        case .locationAlways:
            return "Allows tracking your complete workout even when the app is in the background"
        case .motion:
            return "Helps detect when you pause during a workout"
        case .healthKit:
            return "Sync your workouts with the Health app"
        }
    }
}

// MARK: - Error Handling Extensions

extension AppError {
    /// Whether this error should be logged
    var shouldLog: Bool {
        switch self {
        case .operationCancelled, .permissionNotDetermined:
            return false
        default:
            return true
        }
    }

    /// Log level for this error
    var logLevel: LogLevel {
        switch self {
        case .locationAccuracyTooLow, .operationCancelled:
            return .warning
        case .permissionNotDetermined:
            return .info
        default:
            return .error
        }
    }

    /// Whether this error should show an alert to the user
    var shouldShowAlert: Bool {
        switch self {
        case .operationCancelled, .permissionNotDetermined:
            return false
        default:
            return true
        }
    }
}

enum LogLevel {
    case info
    case warning
    case error
}

// MARK: - Equatable Conformance

extension AppError {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        // Location Errors
        case (.locationPermissionDenied, .locationPermissionDenied),
             (.locationPermissionRestricted, .locationPermissionRestricted),
             (.locationUnavailable, .locationUnavailable),
             (.locationAccuracyTooLow, .locationAccuracyTooLow):
            return true
        case (.locationServicesFailed, .locationServicesFailed):
            return true // Compare case only, not underlying error

        // Database Errors
        case (.databaseReadFailed, .databaseReadFailed),
             (.databaseWriteFailed, .databaseWriteFailed),
             (.databaseDeleteFailed, .databaseDeleteFailed):
            return true
        case (.databaseCorrupted, .databaseCorrupted),
             (.recordNotFound, .recordNotFound):
            return true

        // Permission Errors
        case (.permissionNotDetermined, .permissionNotDetermined):
            return true
        case (.permissionDenied(let lhsType), .permissionDenied(let rhsType)),
             (.permissionRestricted(let lhsType), .permissionRestricted(let rhsType)):
            return lhsType == rhsType

        // Workout Errors
        case (.workoutAlreadyActive, .workoutAlreadyActive),
             (.noActiveWorkout, .noActiveWorkout),
             (.insufficientDataForWorkout, .insufficientDataForWorkout):
            return true
        case (.workoutSaveFailed, .workoutSaveFailed):
            return true

        // HealthKit Errors
        case (.healthKitNotAvailable, .healthKitNotAvailable),
             (.healthKitPermissionDenied, .healthKitPermissionDenied):
            return true
        case (.healthKitWriteFailed, .healthKitWriteFailed),
             (.healthKitReadFailed, .healthKitReadFailed):
            return true

        // Network Errors
        case (.networkUnavailable, .networkUnavailable),
             (.networkTimeout, .networkTimeout):
            return true
        case (.networkFailed, .networkFailed):
            return true

        // Import/Export Errors
        case (.exportFailed, .exportFailed),
             (.importFailed, .importFailed):
            return true
        case (.invalidFileFormat, .invalidFileFormat),
             (.fileNotFound, .fileNotFound):
            return true

        // General Errors
        case (.unknown, .unknown):
            return true
        case (.invalidInput(let lhsMsg), .invalidInput(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.operationCancelled, .operationCancelled):
            return true

        default:
            return false
        }
    }
}

extension PermissionType: Equatable {}

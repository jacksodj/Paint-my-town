//
//  WorkoutPersistenceService.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData
import UIKit

/// Service responsible for persisting workout data to Core Data
/// Handles batch inserts, error recovery, and background task management
class WorkoutPersistenceService: WorkoutPersistenceServiceProtocol {
    // MARK: - Properties

    private let coreDataStack: CoreDataStack
    private let activityRepository: ActivityRepositoryProtocol
    private let recoveryService: RecoveryService

    /// Progress callback for save operations
    typealias ProgressHandler = (SaveProgress) -> Void

    // MARK: - Initialization

    init(
        coreDataStack: CoreDataStack = .shared,
        activityRepository: ActivityRepositoryProtocol,
        recoveryService: RecoveryService
    ) {
        self.coreDataStack = coreDataStack
        self.activityRepository = activityRepository
        self.recoveryService = recoveryService
    }

    // MARK: - Save Workout

    /// Save a completed workout to Core Data
    /// - Parameters:
    ///   - activeWorkout: The active workout to save
    ///   - notes: Optional notes to attach to the workout
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: The saved Activity with persisted ID
    func saveWorkout(
        _ activeWorkout: ActiveWorkout,
        notes: String? = nil,
        progressHandler: ProgressHandler? = nil
    ) async throws -> Activity {
        // Validate workout data
        try WorkoutPersistenceError.validate(activeWorkout)

        // Report validation complete
        progressHandler?(SaveProgress(phase: .validating, progress: 1.0))

        // Convert to Activity domain model
        let activity = activeWorkout.toActivity(notes: notes)

        // Start background task to ensure completion even if app is backgrounded
        let backgroundTaskID = await startBackgroundTask()
        defer { endBackgroundTask(backgroundTaskID) }

        do {
            // Try to save the workout with retry logic
            let savedActivity = try await saveWithRetry(
                activity: activity,
                maxRetries: 3,
                progressHandler: progressHandler
            )

            // Clear recovery data on successful save
            await recoveryService.clearWorkoutState()

            // Report completion
            progressHandler?(SaveProgress(phase: .completed, progress: 1.0))

            return savedActivity

        } catch {
            // On failure, save to recovery storage
            try? await recoveryService.saveWorkoutState(activeWorkout)

            // Rethrow the error
            throw WorkoutPersistenceError.saveFailed(underlying: error)
        }
    }

    // MARK: - Save with Retry

    /// Save workout with retry logic for transient failures
    private func saveWithRetry(
        activity: Activity,
        maxRetries: Int,
        progressHandler: ProgressHandler?
    ) async throws -> Activity {
        var lastError: Error?
        var attempt = 0

        while attempt < maxRetries {
            do {
                return try await performSave(
                    activity: activity,
                    progressHandler: progressHandler
                )
            } catch let error as WorkoutPersistenceError {
                lastError = error

                // Only retry if the error is retryable
                guard error.shouldRetry else {
                    throw error
                }

                attempt += 1

                // Wait before retry (exponential backoff)
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) * 0.5 // 0.5s, 1s, 2s
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                attempt += 1

                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) * 0.5
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        // All retries exhausted
        throw lastError ?? WorkoutPersistenceError.saveFailed(
            underlying: NSError(domain: "WorkoutPersistence", code: -1)
        )
    }

    // MARK: - Perform Save

    /// Perform the actual save operation
    private func performSave(
        activity: Activity,
        progressHandler: ProgressHandler?
    ) async throws -> Activity {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            // Phase 1: Save Activity metadata
            progressHandler?(SaveProgress(phase: .savingActivity, progress: 0.0))

            let activityEntity = ActivityEntity(context: context)
            activityEntity.update(from: activity)

            try self.coreDataStack.saveContext(context)

            progressHandler?(SaveProgress(phase: .savingActivity, progress: 1.0))

            // Phase 2: Batch insert LocationSamples
            progressHandler?(SaveProgress(phase: .savingLocations, progress: 0.0))

            try self.batchInsertLocations(
                activity.locations,
                activityEntity: activityEntity,
                context: context
            ) { current, total in
                let progress = Double(current) / Double(total)
                progressHandler?(SaveProgress(phase: .savingLocations, progress: progress))
            }

            // Phase 3: Save Splits
            progressHandler?(SaveProgress(phase: .savingSplits, progress: 0.0))

            for split in activity.splits {
                let splitEntity = SplitEntity.fromDomain(split, context: context)
                activityEntity.addToSplits(splitEntity)
            }

            try self.coreDataStack.saveContext(context)

            progressHandler?(SaveProgress(phase: .savingSplits, progress: 1.0))

            // Return the saved activity
            return activity
        }
    }

    // MARK: - Batch Insert Locations

    /// Batch insert location samples efficiently
    private func batchInsertLocations(
        _ locations: [LocationSample],
        activityEntity: ActivityEntity,
        context: NSManagedObjectContext,
        progressHandler: @escaping (Int, Int) -> Void
    ) throws {
        guard !locations.isEmpty else { return }

        // For large datasets, use batch insert
        if locations.count > 1000 {
            try batchInsertUsingBatchRequest(
                locations,
                activityID: activityEntity.id,
                progressHandler: progressHandler
            )
        } else {
            // For smaller datasets, use regular insert
            try regularInsertLocations(
                locations,
                activityEntity: activityEntity,
                context: context,
                progressHandler: progressHandler
            )
        }
    }

    /// Batch insert using NSBatchInsertRequest for large datasets
    private func batchInsertUsingBatchRequest(
        _ locations: [LocationSample],
        activityID: UUID,
        progressHandler: @escaping (Int, Int) -> Void
    ) throws {
        // Convert locations to dictionaries
        let locationDicts = locations.map { location -> [String: Any] in
            [
                "id": location.id,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "altitude": location.altitude,
                "horizontalAccuracy": location.horizontalAccuracy,
                "verticalAccuracy": location.verticalAccuracy,
                "timestamp": location.timestamp,
                "speed": location.speed
            ]
        }

        // Perform batch insert
        try coreDataStack.batchInsert(
            entityName: "LocationSampleEntity",
            objects: locationDicts,
            progressHandler: progressHandler
        )

        // Note: Setting the relationship requires a follow-up fetch and update
        // This is done after batch insert to maintain referential integrity
        try setLocationActivityRelationship(activityID: activityID)
    }

    /// Set activity relationship for batch-inserted locations
    private func setLocationActivityRelationship(activityID: UUID) throws {
        let context = coreDataStack.newBackgroundContext()

        try context.performAndWait {
            // Fetch the activity
            let activityFetch = ActivityEntity.fetchRequest()
            activityFetch.predicate = NSPredicate(format: "id == %@", activityID as CVarArg)
            activityFetch.fetchLimit = 1

            guard let activityEntity = try context.fetch(activityFetch).first else {
                throw CoreDataError.objectNotFound
            }

            // Fetch all locations without an activity (just inserted)
            let locationFetch = LocationSampleEntity.fetchRequest()
            locationFetch.predicate = NSPredicate(format: "activity == nil")

            let locationEntities = try context.fetch(locationFetch)

            // Set the relationship
            for locationEntity in locationEntities {
                activityEntity.addToLocations(locationEntity)
            }

            try self.coreDataStack.saveContext(context)
        }
    }

    /// Regular insert for smaller datasets
    private func regularInsertLocations(
        _ locations: [LocationSample],
        activityEntity: ActivityEntity,
        context: NSManagedObjectContext,
        progressHandler: @escaping (Int, Int) -> Void
    ) throws {
        for (index, location) in locations.enumerated() {
            let locationEntity = LocationSampleEntity.fromDomain(location, context: context)
            activityEntity.addToLocations(locationEntity)

            // Save in batches to manage memory
            if (index + 1) % 100 == 0 {
                try context.save()
            }

            // Report progress
            if (index + 1) % max(1, locations.count / 10) == 0 {
                progressHandler(index + 1, locations.count)
            }
        }

        // Final save
        if context.hasChanges {
            try context.save()
        }

        progressHandler(locations.count, locations.count)
    }

    // MARK: - Background Task Management

    /// Start a background task to ensure save completes
    @MainActor
    private func startBackgroundTask() -> UIBackgroundTaskIdentifier {
        var backgroundTaskID = UIBackgroundTaskIdentifier.invalid

        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            // Task expired, clean up
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }

        return backgroundTaskID
    }

    /// End the background task
    @MainActor
    private func endBackgroundTask(_ taskID: UIBackgroundTaskIdentifier) {
        guard taskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskID)
    }
}

// MARK: - Save Progress

/// Represents the progress of a workout save operation
struct SaveProgress {
    enum Phase {
        case validating
        case savingActivity
        case savingLocations
        case savingSplits
        case completed

        var displayName: String {
            switch self {
            case .validating: return "Validating workout data"
            case .savingActivity: return "Saving activity"
            case .savingLocations: return "Saving GPS data"
            case .savingSplits: return "Saving splits"
            case .completed: return "Completed"
            }
        }
    }

    let phase: Phase
    let progress: Double // 0.0 to 1.0

    /// Overall progress across all phases
    var overallProgress: Double {
        let phaseWeight: Double
        switch phase {
        case .validating: phaseWeight = 0.05
        case .savingActivity: phaseWeight = 0.10
        case .savingLocations: phaseWeight = 0.75 // Largest phase
        case .savingSplits: phaseWeight = 0.10
        case .completed: return 1.0
        }

        let phaseBaseProgress: Double
        switch phase {
        case .validating: phaseBaseProgress = 0.0
        case .savingActivity: phaseBaseProgress = 0.05
        case .savingLocations: phaseBaseProgress = 0.15
        case .savingSplits: phaseBaseProgress = 0.90
        case .completed: return 1.0
        }

        return phaseBaseProgress + (progress * phaseWeight)
    }
}

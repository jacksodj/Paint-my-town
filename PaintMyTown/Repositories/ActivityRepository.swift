//
//  ActivityRepository.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

/// Core Data implementation of ActivityRepositoryProtocol
class ActivityRepository: ActivityRepositoryProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    func create(activity: Activity) async throws -> Activity {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            _ = ActivityEntity.fromDomain(activity, context: context)

            do {
                try self.coreDataStack.saveContext(context)
                return activity
            } catch {
                throw CoreDataError.saveFailed(underlying: error)
            }
        }
    }

    /// Create activity with optimized batch insert for large location datasets
    /// - Parameters:
    ///   - activity: The activity to save
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: The saved activity
    func createWithBatchInsert(
        activity: Activity,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws -> Activity {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            // Create activity entity (without locations and splits initially)
            let entity = ActivityEntity(context: context)
            entity.update(from: activity)

            // Save activity first
            try self.coreDataStack.saveContext(context)

            // Batch insert locations if there are many
            if activity.locations.count > 1000 {
                try self.batchInsertLocations(
                    activity.locations,
                    activityID: activity.id,
                    progressHandler: progressHandler
                )
            } else {
                // Regular insert for smaller datasets
                for (index, location) in activity.locations.enumerated() {
                    let locationEntity = LocationSampleEntity.fromDomain(location, context: context)
                    entity.addToLocations(locationEntity)

                    if (index + 1) % 100 == 0 {
                        try context.save()
                    }

                    progressHandler?(index + 1, activity.locations.count)
                }
            }

            // Insert splits
            for split in activity.splits {
                let splitEntity = SplitEntity.fromDomain(split, context: context)
                entity.addToSplits(splitEntity)
            }

            // Final save
            try self.coreDataStack.saveContext(context)

            return activity
        }
    }

    /// Batch insert location samples for an activity
    private func batchInsertLocations(
        _ locations: [LocationSample],
        activityID: UUID,
        progressHandler: ((Int, Int) -> Void)?
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

        // Set relationship to activity
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

            // Fetch locations without activity relationship
            let locationFetch = LocationSampleEntity.fetchRequest()
            locationFetch.predicate = NSPredicate(format: "activity == nil")

            let locationEntities = try context.fetch(locationFetch)

            // Set relationships
            for locationEntity in locationEntities {
                activityEntity.addToLocations(locationEntity)
            }

            try self.coreDataStack.saveContext(context)
        }
    }

    // MARK: - Fetch

    func fetchAll() async throws -> [Activity] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = ActivityEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { $0.toDomain() }
            } catch {
                throw CoreDataError.fetchFailed(underlying: error)
            }
        }
    }

    func fetch(filter: ActivityFilter) async throws -> [Activity] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = ActivityEntity.fetchRequest()
            fetchRequest.predicate = self.buildPredicate(from: filter)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { $0.toDomain() }
            } catch {
                throw CoreDataError.fetchFailed(underlying: error)
            }
        }
    }

    func fetch(id: UUID) async throws -> Activity? {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = ActivityEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                let entities = try context.fetch(fetchRequest)
                return entities.first?.toDomain()
            } catch {
                throw CoreDataError.fetchFailed(underlying: error)
            }
        }
    }

    // MARK: - Update

    func update(activity: Activity) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            let fetchRequest = ActivityEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", activity.id as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                let entities = try context.fetch(fetchRequest)

                guard let entity = entities.first else {
                    throw CoreDataError.objectNotFound
                }

                // Update the entity
                entity.update(from: activity)

                // Update locations (remove old, add new)
                if let oldLocations = entity.locations as? Set<LocationSampleEntity> {
                    entity.removeFromLocations(oldLocations as NSSet)
                }
                for location in activity.locations {
                    let locationEntity = LocationSampleEntity.fromDomain(location, context: context)
                    entity.addToLocations(locationEntity)
                }

                // Update splits (remove old, add new)
                if let oldSplits = entity.splits as? Set<SplitEntity> {
                    entity.removeFromSplits(oldSplits as NSSet)
                }
                for split in activity.splits {
                    let splitEntity = SplitEntity.fromDomain(split, context: context)
                    entity.addToSplits(splitEntity)
                }

                try self.coreDataStack.saveContext(context)
            } catch let error as CoreDataError {
                throw error
            } catch {
                throw CoreDataError.saveFailed(underlying: error)
            }
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            let fetchRequest = ActivityEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                let entities = try context.fetch(fetchRequest)

                guard let entity = entities.first else {
                    throw CoreDataError.objectNotFound
                }

                context.delete(entity)
                try self.coreDataStack.saveContext(context)
            } catch let error as CoreDataError {
                throw error
            } catch {
                throw CoreDataError.deleteFailed(underlying: error)
            }
        }
    }

    func deleteAll() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ActivityEntity.fetchRequest()

        do {
            try coreDataStack.batchDelete(fetchRequest: fetchRequest)
        } catch {
            throw CoreDataError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Helper Methods

    private func buildPredicate(from filter: ActivityFilter) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        // Date range filter
        if let dateRange = filter.dateRange {
            predicates.append(NSPredicate(
                format: "startDate >= %@ AND startDate <= %@",
                dateRange.start as NSDate,
                dateRange.end as NSDate
            ))
        }

        // Activity type filter
        if let types = filter.activityTypes, !types.isEmpty {
            let typeStrings = types.map { $0.rawValue }
            predicates.append(NSPredicate(format: "type IN %@", typeStrings))
        }

        // Distance filter
        if let minDistance = filter.minDistance {
            predicates.append(NSPredicate(format: "distance >= %f", minDistance))
        }
        if let maxDistance = filter.maxDistance {
            predicates.append(NSPredicate(format: "distance <= %f", maxDistance))
        }

        // Duration filter
        if let minDuration = filter.minDuration {
            predicates.append(NSPredicate(format: "duration >= %f", minDuration))
        }
        if let maxDuration = filter.maxDuration {
            predicates.append(NSPredicate(format: "duration <= %f", maxDuration))
        }

        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

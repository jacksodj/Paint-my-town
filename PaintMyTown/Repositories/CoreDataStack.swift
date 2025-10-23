//
//  CoreDataStack.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

/// Core Data stack manager for the application
class CoreDataStack {
    static let shared = CoreDataStack()

    /// The persistent container for the application
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PaintMyTown", managedObjectModel: CoreDataModel.createModel())

        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        // Configure automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        return container
    }()

    /// Main view context (for UI updates on main thread)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Create a new background context for async operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    /// Initialize with in-memory store (for testing)
    static func inMemory() -> CoreDataStack {
        let stack = CoreDataStack()
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        stack.persistentContainer.persistentStoreDescriptions = [description]
        stack.persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load in-memory persistent stores: \(error)")
            }
        }

        return stack
    }

    // MARK: - Save Context

    /// Save the view context
    func saveContext() throws {
        let context = viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    /// Save a specific context
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        if context == viewContext {
            try context.save()
        } else {
            // For background contexts, save and wait
            var saveError: Error?
            context.performAndWait {
                do {
                    try context.save()
                } catch {
                    saveError = error
                }
            }

            if let error = saveError {
                throw error
            }
        }
    }

    // MARK: - Batch Operations

    /// Perform a batch delete request
    func batchDelete(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult

        if let objectIDArray = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }

    /// Perform a batch insert request with progress reporting
    /// - Parameters:
    ///   - entityName: Name of the entity to insert
    ///   - objects: Array of dictionaries containing the data to insert
    ///   - progressHandler: Optional closure called with progress updates (current, total)
    /// - Returns: Array of NSManagedObjectIDs of inserted objects
    @discardableResult
    func batchInsert(
        entityName: String,
        objects: [[String: Any]],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) throws -> [NSManagedObjectID] {
        guard !objects.isEmpty else { return [] }

        let context = newBackgroundContext()
        var insertedObjectIDs: [NSManagedObjectID] = []

        try context.performAndWait {
            // For very large datasets (> 1000), use NSBatchInsertRequest
            if objects.count > 1000 {
                insertedObjectIDs = try performBatchInsertRequest(
                    entityName: entityName,
                    objects: objects,
                    context: context,
                    progressHandler: progressHandler
                )
            } else {
                // For smaller datasets, use regular inserts (faster for small batches)
                insertedObjectIDs = try performRegularInsert(
                    entityName: entityName,
                    objects: objects,
                    context: context,
                    progressHandler: progressHandler
                )
            }
        }

        // Merge changes to view context
        let changes = [NSInsertedObjectsKey: insertedObjectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])

        return insertedObjectIDs
    }

    /// Perform batch insert using NSBatchInsertRequest for large datasets
    private func performBatchInsertRequest(
        entityName: String,
        objects: [[String: Any]],
        context: NSManagedObjectContext,
        progressHandler: ((Int, Int) -> Void)?
    ) throws -> [NSManagedObjectID] {
        var insertedObjectIDs: [NSManagedObjectID] = []
        let batchSize = 1000 // Process 1000 at a time
        let batches = stride(from: 0, to: objects.count, by: batchSize).map {
            Array(objects[$0..<min($0 + batchSize, objects.count)])
        }

        for (index, batch) in batches.enumerated() {
            var batchIndex = 0
            let batchInsertRequest = NSBatchInsertRequest(
                entityName: entityName,
                dictionaryHandler: { dict in
                    guard batchIndex < batch.count else { return true }
                    dict.addEntries(from: batch[batchIndex])
                    batchIndex += 1
                    return false
                }
            )

            batchInsertRequest.resultType = .objectIDs

            let result = try context.execute(batchInsertRequest) as? NSBatchInsertResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                insertedObjectIDs.append(contentsOf: objectIDs)
            }

            // Report progress
            let processed = min((index + 1) * batchSize, objects.count)
            progressHandler?(processed, objects.count)
        }

        return insertedObjectIDs
    }

    /// Perform regular insert for smaller datasets
    private func performRegularInsert(
        entityName: String,
        objects: [[String: Any]],
        context: NSManagedObjectContext,
        progressHandler: ((Int, Int) -> Void)?
    ) throws -> [NSManagedObjectID] {
        var insertedObjectIDs: [NSManagedObjectID] = []

        for (index, objectDict) in objects.enumerated() {
            let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)

            for (key, value) in objectDict {
                entity.setValue(value, forKey: key)
            }

            // Save in batches to avoid memory issues
            if (index + 1) % 100 == 0 {
                try context.save()
                context.reset() // Free memory
            }

            insertedObjectIDs.append(entity.objectID)

            // Report progress every 10%
            if (index + 1) % max(1, objects.count / 10) == 0 {
                progressHandler?(index + 1, objects.count)
            }
        }

        // Final save
        if context.hasChanges {
            try context.save()
        }

        progressHandler?(objects.count, objects.count)

        return insertedObjectIDs
    }
}

// MARK: - Core Data Errors

enum CoreDataError: Error, LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case objectNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .objectNotFound:
            return "The requested object was not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

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

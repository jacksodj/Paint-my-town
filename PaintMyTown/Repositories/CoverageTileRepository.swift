//
//  CoverageTileRepository.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData
import MapKit

/// Core Data implementation of CoverageTileRepositoryProtocol
class CoverageTileRepository: CoverageTileRepositoryProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Upsert

    func upsertTiles(_ tiles: [CoverageTile]) async throws {
        guard !tiles.isEmpty else { return }

        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            for tile in tiles {
                // Check if tile already exists
                let fetchRequest = CoverageTileEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "geohash == %@", tile.geohash)
                fetchRequest.fetchLimit = 1

                do {
                    let existingEntities = try context.fetch(fetchRequest)

                    if let existingEntity = existingEntities.first {
                        // Update existing tile
                        existingEntity.visitCount += Int32(tile.visitCount)
                        existingEntity.lastVisited = max(existingEntity.lastVisited, tile.lastVisited)
                        existingEntity.firstVisited = min(existingEntity.firstVisited, tile.firstVisited)
                    } else {
                        // Create new tile
                        _ = CoverageTileEntity.fromDomain(tile, context: context)
                    }
                } catch {
                    throw CoreDataError.fetchFailed(underlying: error)
                }
            }

            do {
                try self.coreDataStack.saveContext(context)
            } catch {
                throw CoreDataError.saveFailed(underlying: error)
            }
        }
    }

    // MARK: - Fetch

    func fetchTiles(in region: MKCoordinateRegion) async throws -> [CoverageTile] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            // Calculate bounding box
            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLon = region.center.longitude - region.span.longitudeDelta / 2
            let maxLon = region.center.longitude + region.span.longitudeDelta / 2

            let fetchRequest = CoverageTileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f",
                minLat, maxLat, minLon, maxLon
            )

            do {
                let entities = try context.fetch(fetchRequest)
                return entities.map { $0.toDomain() }
            } catch {
                throw CoreDataError.fetchFailed(underlying: error)
            }
        }
    }

    func fetchTiles(matching geohashes: [String]) async throws -> [CoverageTile] {
        guard !geohashes.isEmpty else { return [] }

        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = CoverageTileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "geohash IN %@", geohashes)

            do {
                let entities = try context.fetch(fetchRequest)
                return entities.map { $0.toDomain() }
            } catch {
                throw CoreDataError.fetchFailed(underlying: error)
            }
        }
    }

    // MARK: - Delete

    func deleteAll() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CoverageTileEntity.fetchRequest()

        do {
            try coreDataStack.batchDelete(fetchRequest: fetchRequest)
        } catch {
            throw CoreDataError.deleteFailed(underlying: error)
        }
    }
}

//
//  RepositoryProtocol.swift
//  PaintMyTown
//
//  Created by Claude on 2025-10-23.
//

import Foundation

/// Base protocol for all repository implementations
/// Repositories are responsible for data access and persistence
protocol RepositoryProtocol {
    associatedtype Entity
    associatedtype Identifier: Hashable

    /// Fetch a single entity by its identifier
    /// - Parameter id: The unique identifier of the entity
    /// - Returns: The entity if found, nil otherwise
    func fetch(id: Identifier) async throws -> Entity?

    /// Fetch all entities
    /// - Returns: An array of all entities
    func fetchAll() async throws -> [Entity]

    /// Create a new entity
    /// - Parameter entity: The entity to create
    /// - Returns: The created entity with updated metadata
    func create(_ entity: Entity) async throws -> Entity

    /// Update an existing entity
    /// - Parameter entity: The entity to update
    /// - Returns: The updated entity
    func update(_ entity: Entity) async throws -> Entity

    /// Delete an entity by its identifier
    /// - Parameter id: The unique identifier of the entity to delete
    func delete(id: Identifier) async throws

    /// Delete all entities (use with caution)
    func deleteAll() async throws
}

/// Protocol for repositories that support filtering
protocol FilterableRepositoryProtocol: RepositoryProtocol {
    associatedtype Filter

    /// Fetch entities matching the provided filter
    /// - Parameter filter: The filter criteria to apply
    /// - Returns: An array of entities matching the filter
    func fetch(filter: Filter) async throws -> [Entity]
}

/// Protocol for repositories that support batch operations
protocol BatchRepositoryProtocol: RepositoryProtocol {
    /// Create multiple entities in a single transaction
    /// - Parameter entities: The entities to create
    /// - Returns: The created entities
    func createBatch(_ entities: [Entity]) async throws -> [Entity]

    /// Delete multiple entities by their identifiers
    /// - Parameter ids: The identifiers of entities to delete
    func deleteBatch(ids: [Identifier]) async throws
}

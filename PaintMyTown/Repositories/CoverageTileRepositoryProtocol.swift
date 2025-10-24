//
//  CoverageTileRepositoryProtocol.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import MapKit

/// Protocol defining the contract for coverage tile data persistence
protocol CoverageTileRepositoryProtocol {
    /// Upsert (insert or update) coverage tiles
    /// - Parameter tiles: Array of coverage tiles to upsert
    func upsertTiles(_ tiles: [CoverageTile]) async throws

    /// Fetch tiles within a geographic region
    /// - Parameter region: The map region to search
    /// - Returns: Array of coverage tiles in the region
    func fetchTiles(in region: MKCoordinateRegion) async throws -> [CoverageTile]

    /// Fetch tiles matching specific geohashes
    /// - Parameter geohashes: Array of geohash strings
    /// - Returns: Array of coverage tiles matching the geohashes
    func fetchTiles(matching geohashes: [String]) async throws -> [CoverageTile]

    /// Delete all coverage tiles
    func deleteAll() async throws
}

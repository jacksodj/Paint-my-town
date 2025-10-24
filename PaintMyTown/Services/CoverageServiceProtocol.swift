//
//  CoverageServiceProtocol.swift
//  PaintMyTown
//
//  Protocol for managing coverage tile generation and visualization
//

import Foundation
import MapKit
import Combine

/// Protocol defining coverage calculation and visualization capabilities
protocol CoverageServiceProtocol: ServiceProtocol {

    /// Publisher that emits coverage calculation progress (0.0 to 1.0)
    var progressPublisher: AnyPublisher<Double, Never> { get }

    /// Publisher that emits when coverage data changes
    var coverageChangedPublisher: AnyPublisher<Void, Never> { get }

    /// Generate coverage tiles from activities
    /// - Parameters:
    ///   - activities: Activities to generate coverage from
    ///   - precision: Geohash precision level (default 7, ~76m tiles)
    /// - Returns: Array of generated coverage tiles
    /// - Throws: CoverageServiceError if generation fails
    func generateCoverageTiles(
        from activities: [Activity],
        precision: Int
    ) async throws -> [CoverageTile]

    /// Calculate and save coverage tiles from filtered activities
    /// - Parameter filter: Filter to apply to activities
    /// - Throws: CoverageServiceError if calculation fails
    func updateCoverage(filter: CoverageFilter?) async throws

    /// Fetch coverage tiles for a map region
    /// - Parameters:
    ///   - region: The map region to fetch tiles for
    ///   - filter: Optional filter to apply
    /// - Returns: Coverage tiles in the region
    /// - Throws: CoverageServiceError if fetch fails
    func fetchCoverageTiles(
        in region: MKCoordinateRegion,
        filter: CoverageFilter?
    ) async throws -> [CoverageTile]

    /// Generate area fill overlay for MapKit
    /// - Parameters:
    ///   - tiles: Coverage tiles to visualize
    ///   - bufferRadius: Buffer radius in meters around each tile (default 50m)
    /// - Returns: MKPolygon overlay representing the covered area
    func generateAreaFillOverlay(
        from tiles: [CoverageTile],
        bufferRadius: Double
    ) -> MKPolygon

    /// Generate heatmap overlay for MapKit
    /// - Parameters:
    ///   - tiles: Coverage tiles to visualize
    ///   - region: Map region for the heatmap
    /// - Returns: MKTileOverlay for rendering the heatmap
    func generateHeatmapOverlay(
        from tiles: [CoverageTile],
        in region: MKCoordinateRegion
    ) -> MKTileOverlay

    /// Calculate coverage statistics
    /// - Parameter filter: Optional filter to apply
    /// - Returns: Coverage statistics
    /// - Throws: CoverageServiceError if calculation fails
    func calculateStatistics(filter: CoverageFilter?) async throws -> CoverageStatistics

    /// Clear all cached coverage data
    func clearCache()

    /// Delete all coverage tiles from database
    /// - Throws: CoverageServiceError if deletion fails
    func deleteAllCoverageTiles() async throws
}

/// Statistics about coverage
struct CoverageStatistics {
    let totalTiles: Int
    let totalVisits: Int
    let firstVisitDate: Date?
    let lastVisitDate: Date?
    let areaInSquareMeters: Double
    let uniqueLocationsVisited: Int

    var areaInSquareKilometers: Double {
        areaInSquareMeters / 1_000_000
    }

    var areaInSquareMiles: Double {
        areaInSquareMeters / 2_589_988
    }
}

/// Errors that can occur in the coverage service
enum CoverageServiceError: Error, LocalizedError {
    case noActivities
    case invalidPrecision(Int)
    case generationFailed(String)
    case repositoryError(Error)
    case invalidRegion

    var errorDescription: String? {
        switch self {
        case .noActivities:
            return "No activities available to generate coverage from."
        case .invalidPrecision(let precision):
            return "Invalid geohash precision: \(precision). Must be between 1 and 12."
        case .generationFailed(let message):
            return "Coverage generation failed: \(message)"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        case .invalidRegion:
            return "Invalid map region provided."
        }
    }
}

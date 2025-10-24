//
//  CoverageService.swift
//  PaintMyTown
//
//  Implementation of coverage tile generation and visualization
//

import Foundation
import MapKit
import Combine

/// Service for managing coverage tiles and visualization
final class CoverageService: CoverageServiceProtocol {

    // MARK: - Dependencies

    private let activityRepository: ActivityRepositoryProtocol
    private let coverageTileRepository: CoverageTileRepositoryProtocol
    private let logger: Logger

    // MARK: - Publishers

    private let progressSubject = PassthroughSubject<Double, Never>()
    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    private let coverageChangedSubject = PassthroughSubject<Void, Never>()
    var coverageChangedPublisher: AnyPublisher<Void, Never> {
        coverageChangedSubject.eraseToAnyPublisher()
    }

    // MARK: - State

    private var overlayCache: [String: MKOverlay] = [:]
    private let cacheLock = NSLock()
    private var cancellables = Set<AnyCancellable>()

    // Default precision for coverage tiles (~76m)
    private let defaultPrecision = 7

    // MARK: - Initialization

    init(
        activityRepository: ActivityRepositoryProtocol,
        coverageTileRepository: CoverageTileRepositoryProtocol,
        logger: Logger
    ) {
        self.activityRepository = activityRepository
        self.coverageTileRepository = coverageTileRepository
        self.logger = logger
    }

    // MARK: - ServiceProtocol

    func initialize() async throws {
        logger.info("CoverageService initialized")
    }

    func cleanup() {
        cancellables.removeAll()
        clearCache()
        logger.info("CoverageService cleaned up")
    }

    // MARK: - Coverage Generation

    func generateCoverageTiles(
        from activities: [Activity],
        precision: Int = 7
    ) async throws -> [CoverageTile] {
        guard !activities.isEmpty else {
            throw CoverageServiceError.noActivities
        }

        guard (1...12).contains(precision) else {
            throw CoverageServiceError.invalidPrecision(precision)
        }

        logger.info("Generating coverage tiles from \(activities.count) activities with precision \(precision)")
        progressSubject.send(0.0)

        var tileDict: [String: TileAccumulator] = [:]
        let totalActivities = Double(activities.count)

        // Process each activity
        for (index, activity) in activities.enumerated() {
            // Generate geohashes for each location in the activity
            for location in activity.locations {
                let geohash = Geohash.encode(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    precision: precision
                )

                if var accumulator = tileDict[geohash] {
                    // Update existing tile
                    accumulator.visitCount += 1
                    accumulator.lastVisited = max(accumulator.lastVisited, location.timestamp)
                    tileDict[geohash] = accumulator
                } else {
                    // Create new tile
                    let box = Geohash.decode(geohash)
                    tileDict[geohash] = TileAccumulator(
                        geohash: geohash,
                        latitude: box.center.latitude,
                        longitude: box.center.longitude,
                        visitCount: 1,
                        firstVisited: location.timestamp,
                        lastVisited: location.timestamp
                    )
                }
            }

            // Report progress
            let progress = Double(index + 1) / totalActivities
            progressSubject.send(progress * 0.8) // 80% for generation
        }

        // Convert accumulators to coverage tiles
        let tiles = tileDict.values.map { accumulator in
            CoverageTile(
                geohash: accumulator.geohash,
                latitude: accumulator.latitude,
                longitude: accumulator.longitude,
                visitCount: accumulator.visitCount,
                firstVisited: accumulator.firstVisited,
                lastVisited: accumulator.lastVisited
            )
        }

        progressSubject.send(1.0)
        logger.info("Generated \(tiles.count) coverage tiles")

        return tiles
    }

    func updateCoverage(filter: CoverageFilter?) async throws {
        logger.info("Updating coverage with filter")
        progressSubject.send(0.0)

        // Fetch activities based on filter
        let activities: [Activity]
        if let filter = filter {
            activities = try await activityRepository.fetch(filter: filter.toActivityFilter())
        } else {
            activities = try await activityRepository.fetchAll()
        }

        guard !activities.isEmpty else {
            logger.warning("No activities found for coverage update")
            progressSubject.send(1.0)
            return
        }

        // Generate coverage tiles
        let tiles = try await generateCoverageTiles(from: activities, precision: defaultPrecision)

        // Clear existing tiles and save new ones
        try await coverageTileRepository.deleteAll()
        try await coverageTileRepository.upsertTiles(tiles)

        // Clear cache and notify
        clearCache()
        coverageChangedSubject.send(())

        logger.info("Coverage updated with \(tiles.count) tiles")
    }

    func fetchCoverageTiles(
        in region: MKCoordinateRegion,
        filter: CoverageFilter?
    ) async throws -> [CoverageTile] {
        logger.debug("Fetching coverage tiles for region")

        // If filter is provided, regenerate tiles on-the-fly
        if let filter = filter {
            let activities = try await activityRepository.fetch(filter: filter.toActivityFilter())
            let tiles = try await generateCoverageTiles(from: activities, precision: defaultPrecision)

            // Filter tiles to region
            return tiles.filter { tile in
                region.contains(coordinate: tile.coordinate)
            }
        } else {
            // Fetch from repository
            return try await coverageTileRepository.fetchTiles(in: region)
        }
    }

    // MARK: - Overlay Generation

    func generateAreaFillOverlay(
        from tiles: [CoverageTile],
        bufferRadius: Double = 50.0
    ) -> MKPolygon {
        logger.debug("Generating area fill overlay from \(tiles.count) tiles")

        // Generate buffered polygons for each tile
        var allCoordinates: [CLLocationCoordinate2D] = []

        for tile in tiles {
            let box = Geohash.decode(tile.geohash)

            // Create a buffered rectangle around the tile
            let halfWidth = (box.longitudeWidth / 2) + (bufferRadius / 111320.0) // Approximate deg to meters
            let halfHeight = (box.latitudeHeight / 2) + (bufferRadius / 110540.0)

            let coords = [
                CLLocationCoordinate2D(
                    latitude: tile.latitude - halfHeight,
                    longitude: tile.longitude - halfWidth
                ),
                CLLocationCoordinate2D(
                    latitude: tile.latitude - halfHeight,
                    longitude: tile.longitude + halfWidth
                ),
                CLLocationCoordinate2D(
                    latitude: tile.latitude + halfHeight,
                    longitude: tile.longitude + halfWidth
                ),
                CLLocationCoordinate2D(
                    latitude: tile.latitude + halfHeight,
                    longitude: tile.longitude - halfWidth
                )
            ]

            allCoordinates.append(contentsOf: coords)
        }

        // Create a convex hull or multi-polygon
        // For simplicity, we'll create individual polygons for each tile
        // A more sophisticated approach would use a proper polygon union algorithm

        return MKPolygon(coordinates: allCoordinates, count: allCoordinates.count)
    }

    func generateHeatmapOverlay(
        from tiles: [CoverageTile],
        in region: MKCoordinateRegion
    ) -> MKTileOverlay {
        logger.debug("Generating heatmap overlay from \(tiles.count) tiles")

        // Create a custom tile overlay
        // For M2 MVP, we'll use a simple implementation
        // A more sophisticated heatmap would require custom tile rendering

        let overlay = HeatmapTileOverlay(tiles: tiles, region: region)
        return overlay
    }

    // MARK: - Statistics

    func calculateStatistics(filter: CoverageFilter?) async throws -> CoverageStatistics {
        logger.debug("Calculating coverage statistics")

        let tiles: [CoverageTile]
        if let filter = filter {
            // Generate tiles on-the-fly for filtered activities
            let activities = try await activityRepository.fetch(filter: filter.toActivityFilter())
            tiles = try await generateCoverageTiles(from: activities, precision: defaultPrecision)
        } else {
            // Fetch all tiles from repository
            tiles = try await coverageTileRepository.fetchTiles(in: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
            ))
        }

        guard !tiles.isEmpty else {
            return CoverageStatistics(
                totalTiles: 0,
                totalVisits: 0,
                firstVisitDate: nil,
                lastVisitDate: nil,
                areaInSquareMeters: 0,
                uniqueLocationsVisited: 0
            )
        }

        let totalVisits = tiles.reduce(0) { $0 + $1.visitCount }
        let firstVisit = tiles.map { $0.firstVisited }.min()
        let lastVisit = tiles.map { $0.lastVisited }.max()

        // Calculate approximate area (each precision 7 tile is ~76m x 76m)
        let dimensions = Geohash.dimensionsForPrecision(defaultPrecision)
        let tileArea = dimensions.width * dimensions.height
        let totalArea = Double(tiles.count) * tileArea

        return CoverageStatistics(
            totalTiles: tiles.count,
            totalVisits: totalVisits,
            firstVisitDate: firstVisit,
            lastVisitDate: lastVisit,
            areaInSquareMeters: totalArea,
            uniqueLocationsVisited: tiles.count
        )
    }

    // MARK: - Cache Management

    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        overlayCache.removeAll()
        logger.debug("Coverage overlay cache cleared")
    }

    func deleteAllCoverageTiles() async throws {
        logger.warning("Deleting all coverage tiles")
        try await coverageTileRepository.deleteAll()
        clearCache()
        coverageChangedSubject.send(())
    }

    // MARK: - Helper Types

    private struct TileAccumulator {
        let geohash: String
        let latitude: Double
        let longitude: Double
        var visitCount: Int
        let firstVisited: Date
        var lastVisited: Date
    }
}

// MARK: - CoverageFilter Extension

private extension CoverageFilter {
    func toActivityFilter() -> ActivityFilter {
        ActivityFilter(
            dateRange: dateRange,
            activityTypes: activityTypes.isEmpty ? nil : activityTypes,
            minDistance: minDistance,
            maxDistance: nil,
            minDuration: minDuration,
            maxDuration: nil
        )
    }
}

// MARK: - MKCoordinateRegion Extension

private extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let halfLatDelta = span.latitudeDelta / 2
        let halfLonDelta = span.longitudeDelta / 2

        let minLat = center.latitude - halfLatDelta
        let maxLat = center.latitude + halfLatDelta
        let minLon = center.longitude - halfLonDelta
        let maxLon = center.longitude + halfLonDelta

        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLon &&
               coordinate.longitude <= maxLon
    }
}

// MARK: - Heatmap Tile Overlay

/// Custom tile overlay for rendering heatmap
private class HeatmapTileOverlay: MKTileOverlay {
    let tiles: [CoverageTile]
    let region: MKCoordinateRegion

    init(tiles: [CoverageTile], region: MKCoordinateRegion) {
        self.tiles = tiles
        self.region = region
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = false
    }

    // Custom tile loading would be implemented here
    // For M2 MVP, we'll use the simpler area fill approach
}

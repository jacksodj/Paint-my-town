//
//  CoverageMapViewModel.swift
//  PaintMyTown
//
//  ViewModel for the coverage map view handling coverage visualization and filtering
//

import Foundation
import MapKit
import Combine
import SwiftUI

/// ViewModel for coverage map visualization
@MainActor
final class CoverageMapViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Coverage tiles to display
    @Published var coverageTiles: [CoverageTile] = []

    /// Current map region
    @Published var mapRegion: MKCoordinateRegion

    /// Current visualization type
    @Published var visualizationType: CoverageAlgorithmType = .areaFill

    /// Current map type (standard, satellite, hybrid)
    @Published var mapType: MKMapType = .standard

    /// Active filter
    @Published var activeFilter: CoverageFilter = .default

    /// Loading state
    @Published var isLoading: Bool = false

    /// Coverage calculation progress (0.0 to 1.0)
    @Published var progress: Double = 0.0

    /// Coverage statistics
    @Published var statistics: CoverageStatistics?

    /// Error message to display
    @Published var errorMessage: String?

    /// Show filter sheet
    @Published var showFilterSheet: Bool = false

    /// Show map style picker
    @Published var showMapStylePicker: Bool = false

    /// Map overlay for rendering
    @Published var mapOverlay: MKOverlay?

    // MARK: - Private Properties

    private let coverageService: CoverageServiceProtocol
    private let activityRepository: ActivityRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // Default region (will be updated to user's location or last known region)
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK: - Initialization

    init(
        coverageService: CoverageServiceProtocol,
        activityRepository: ActivityRepositoryProtocol
    ) {
        self.coverageService = coverageService
        self.activityRepository = activityRepository
        self.mapRegion = defaultRegion

        setupSubscriptions()
    }

    convenience init() {
        let container = DependencyContainer.shared
        let coverageService = container.resolve(CoverageServiceProtocol.self)
        let activityRepository = container.resolve(ActivityRepositoryProtocol.self)
        self.init(coverageService: coverageService, activityRepository: activityRepository)
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to coverage progress updates
        coverageService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &cancellables)

        // Subscribe to coverage changes
        coverageService.coverageChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.loadCoverage() }
            }
            .store(in: &cancellables)

        // Load initial coverage data
        Task {
            await loadInitialData()
        }
    }

    // MARK: - Public Methods

    /// Load initial coverage data
    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to load existing coverage tiles
            let tiles = try await coverageService.fetchCoverageTiles(in: mapRegion, filter: nil)

            if tiles.isEmpty {
                // No coverage tiles exist, generate them
                try await coverageService.updateCoverage(filter: nil)
            } else {
                coverageTiles = tiles
                await updateMapRegion(for: tiles)
                await updateOverlay()
            }

            // Load statistics
            statistics = try await coverageService.calculateStatistics(filter: nil)

        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.error("Failed to load coverage: \(error)", category: .general)
        }

        isLoading = false
    }

    /// Load coverage for the current map region
    func loadCoverage() async {
        isLoading = true
        errorMessage = nil

        do {
            coverageTiles = try await coverageService.fetchCoverageTiles(
                in: mapRegion,
                filter: activeFilter
            )
            await updateOverlay()

            // Update statistics
            statistics = try await coverageService.calculateStatistics(filter: activeFilter)

        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.error("Failed to load coverage: \(error)", category: .general)
        }

        isLoading = false
    }

    /// Apply a filter to the coverage
    func applyFilter(_ filter: CoverageFilter) async {
        activeFilter = filter
        await loadCoverage()
    }

    /// Clear the current filter
    func clearFilter() async {
        activeFilter = .default
        await loadCoverage()
    }

    /// Change visualization type
    func changeVisualizationType(_ type: CoverageAlgorithmType) async {
        visualizationType = type
        await updateOverlay()
    }

    /// Update map region (called when user pans/zooms)
    func updateMapRegion(_ region: MKCoordinateRegion) async {
        mapRegion = region
        await loadCoverage()
    }

    /// Refresh coverage data
    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            try await coverageService.updateCoverage(filter: activeFilter)
            await loadCoverage()
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.error("Failed to refresh coverage: \(error)", category: .general)
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// Update the map overlay based on visualization type
    private func updateOverlay() async {
        guard !coverageTiles.isEmpty else {
            mapOverlay = nil
            return
        }

        switch visualizationType {
        case .areaFill:
            mapOverlay = coverageService.generateAreaFillOverlay(
                from: coverageTiles,
                bufferRadius: 50.0
            )

        case .heatmap:
            mapOverlay = coverageService.generateHeatmapOverlay(
                from: coverageTiles,
                in: mapRegion
            )

        case .routeLines:
            // Route lines would require fetching full activities
            // For now, fall back to area fill
            mapOverlay = coverageService.generateAreaFillOverlay(
                from: coverageTiles,
                bufferRadius: 50.0
            )
        }
    }

    /// Update map region to fit coverage tiles
    private func updateMapRegion(for tiles: [CoverageTile]) async {
        guard !tiles.isEmpty else { return }

        // Calculate bounding box for all tiles
        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity

        for tile in tiles {
            minLat = min(minLat, tile.latitude)
            maxLat = max(maxLat, tile.latitude)
            minLon = min(minLon, tile.longitude)
            maxLon = max(maxLon, tile.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.2, 0.01), // 20% padding, min 0.01
            longitudeDelta: max((maxLon - minLon) * 1.2, 0.01)
        )

        mapRegion = MKCoordinateRegion(center: center, span: span)
    }

    /// Format distance for display
    func formattedArea(unit: DistanceUnit = .kilometers) -> String {
        guard let stats = statistics else { return "0.00 km²" }

        let area = unit == .kilometers ? stats.areaInSquareKilometers : stats.areaInSquareMiles
        let unitSymbol = unit == .kilometers ? "km²" : "mi²"

        return String(format: "%.2f %@", area, unitSymbol)
    }

    /// Get count of active filters
    func activeFilterCount() -> Int {
        var count = 0
        if activeFilter.dateRange != nil { count += 1 }
        if !activeFilter.activityTypes.isEmpty &&
           activeFilter.activityTypes.count < ActivityType.allCases.count {
            count += 1
        }
        if activeFilter.minDistance != nil { count += 1 }
        if activeFilter.minDuration != nil { count += 1 }
        return count
    }
}

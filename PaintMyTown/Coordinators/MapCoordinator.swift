//
//  MapCoordinator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Coordinator managing the Map tab navigation
@MainActor
class MapCoordinator: ObservableObject, Coordinator {
    // MARK: - Properties

    var childCoordinators: [Coordinator] = []

    @Published var presentedSheet: MapSheet?
    @Published var navigationPath = NavigationPath()
    @Published var activeFilter: CoverageFilter = .default

    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Coordinator

    func start() {
        // Initial setup for Map tab
    }

    // MARK: - Navigation

    /// Shows the filter sheet
    func showFilterSheet() {
        presentedSheet = .filter
    }

    /// Shows the map style picker
    func showMapStylePicker() {
        presentedSheet = .mapStyle
    }

    /// Applies a coverage filter
    func applyFilter(_ filter: CoverageFilter) {
        activeFilter = filter
        appState.logger.info("Applied coverage filter", category: .ui)
    }

    /// Dismisses the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
}

// MARK: - Supporting Types

enum MapSheet: Identifiable {
    case filter
    case mapStyle

    var id: String {
        switch self {
        case .filter: return "filter"
        case .mapStyle: return "mapStyle"
        }
    }
}

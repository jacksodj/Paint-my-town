//
//  HistoryCoordinator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Coordinator managing the History tab navigation
@MainActor
class HistoryCoordinator: ObservableObject, Coordinator {
    // MARK: - Properties

    var childCoordinators: [Coordinator] = []

    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: HistorySheet?
    @Published var selectedWorkoutId: UUID?

    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Coordinator

    func start() {
        // Initial setup for History tab
    }

    // MARK: - Navigation

    /// Shows a specific workout detail
    func showWorkout(id: UUID) {
        selectedWorkoutId = id
        // TODO: Push to navigation path when ActivityDetailView is implemented
        appState.logger.info("Showing workout: \(id.uuidString)", category: .ui)
    }

    /// Shows the search/filter sheet
    func showSearchSheet() {
        presentedSheet = .search
    }

    /// Shows the sort options sheet
    func showSortSheet() {
        presentedSheet = .sort
    }

    /// Dismisses the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
}

// MARK: - Supporting Types

enum HistorySheet: Identifiable {
    case search
    case sort

    var id: String {
        switch self {
        case .search: return "search"
        case .sort: return "sort"
        }
    }
}

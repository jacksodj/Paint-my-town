//
//  ProfileCoordinator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Coordinator managing the Profile tab navigation
@MainActor
class ProfileCoordinator: ObservableObject, Coordinator {
    // MARK: - Properties

    var childCoordinators: [Coordinator] = []

    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: ProfileSheet?

    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Coordinator

    func start() {
        // Initial setup for Profile tab
    }

    // MARK: - Navigation

    /// Shows the settings screen
    func showSettings() {
        // TODO: Push to navigation path when SettingsView is implemented
        appState.logger.info("Showing settings", category: .ui)
    }

    /// Shows the permissions management screen
    func showPermissions() {
        presentedSheet = .permissions
    }

    /// Shows the data management screen
    func showDataManagement() {
        presentedSheet = .dataManagement
    }

    /// Shows the about screen
    func showAbout() {
        presentedSheet = .about
    }

    /// Dismisses the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
}

// MARK: - Supporting Types

enum ProfileSheet: Identifiable {
    case permissions
    case dataManagement
    case about

    var id: String {
        switch self {
        case .permissions: return "permissions"
        case .dataManagement: return "dataManagement"
        case .about: return "about"
        }
    }
}

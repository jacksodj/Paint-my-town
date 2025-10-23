//
//  Coordinator.swift
//  PaintMyTown
//
//  Created by Claude on 2025-10-23.
//

import Foundation
import SwiftUI

/// Base protocol for all coordinators
/// Coordinators manage navigation and flow between screens
protocol Coordinator: AnyObject {
    /// Child coordinators managed by this coordinator
    var childCoordinators: [Coordinator] { get set }

    /// Start the coordinator's flow
    func start()

    /// Clean up the coordinator and its children
    func finish()
}

extension Coordinator {
    /// Add a child coordinator
    /// - Parameter coordinator: The coordinator to add
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    /// Remove a child coordinator
    /// - Parameter coordinator: The coordinator to remove
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    /// Default finish implementation that cleans up all children
    func finish() {
        childCoordinators.forEach { $0.finish() }
        childCoordinators.removeAll()
    }
}

/// Protocol for coordinators that present views in SwiftUI
protocol ViewCoordinator: Coordinator {
    associatedtype ViewType: View

    /// The root view managed by this coordinator
    var rootView: ViewType { get }
}

/// Protocol for coordinators that handle navigation events
protocol NavigationCoordinator: Coordinator {
    /// Navigate to a specific destination
    /// - Parameter destination: The destination to navigate to
    func navigate(to destination: Any)

    /// Go back to the previous screen
    func navigateBack()

    /// Return to the root of the navigation stack
    func navigateToRoot()
}

/// Protocol for coordinators that present modals
protocol ModalCoordinator: Coordinator {
    /// Present a view modally
    /// - Parameter destination: The destination to present
    func presentModal(_ destination: Any)

    /// Dismiss the current modal
    func dismissModal()
}

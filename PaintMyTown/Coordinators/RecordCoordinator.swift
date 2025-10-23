//
//  RecordCoordinator.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Coordinator managing the Record tab navigation
@MainActor
class RecordCoordinator: ObservableObject, Coordinator {
    // MARK: - Properties

    var childCoordinators: [Coordinator] = []

    @Published var presentedSheet: RecordSheet?
    @Published var navigationPath = NavigationPath()

    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Coordinator

    func start() {
        // Initial setup for Record tab
    }

    // MARK: - Navigation

    /// Starts a workout with the specified activity type
    func startWorkout(type: ActivityType) {
        // TODO: Implement in M1 when WorkoutService is available
        appState.logger.info("Starting workout of type: \(type.rawValue)", category: .ui)
    }

    /// Shows the workout summary sheet
    func showWorkoutSummary() {
        presentedSheet = .workoutSummary
    }

    /// Dismisses the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
}

// MARK: - Supporting Types

enum RecordSheet: Identifiable {
    case workoutSummary
    case activityTypeSelector

    var id: String {
        switch self {
        case .workoutSummary: return "workoutSummary"
        case .activityTypeSelector: return "activityTypeSelector"
        }
    }
}

//
//  AppState.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import Combine

/// Global application state managing app-wide shared data
/// Singleton ObservableObject accessible throughout the app
@MainActor
final class AppState: ObservableObject {
    // MARK: - Singleton

    static let shared = AppState()

    private init() {
        // Initialize settings
        self.settings = UserDefaultsManager.shared

        // Subscribe to workout state changes
        setupObservers()
    }

    // MARK: - Published Properties

    /// Location authorization status
    @Published var isLocationAuthorized: Bool = false

    /// Background location authorization status
    @Published var isBackgroundLocationAuthorized: Bool = false

    /// Motion & Fitness authorization status
    @Published var isMotionAuthorized: Bool = false

    /// HealthKit authorization status
    @Published var isHealthKitAuthorized: Bool = false

    /// Current active workout (nil if no workout in progress)
    @Published var activeWorkout: ActiveWorkout?

    /// Currently displayed error (for app-level error handling)
    @Published var currentError: AppError?

    /// App-wide loading state
    @Published var isLoading: Bool = false

    /// Whether the app is running in background
    @Published var isInBackground: Bool = false

    /// User settings manager
    let settings: UserDefaultsManager

    /// App logger
    let logger = Logger.shared

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let permissionManager = PermissionManager()

    // MARK: - Setup

    private func setupObservers() {
        // Observe active workout changes
        $activeWorkout
            .sink { [weak self] workout in
                if let workout = workout {
                    self?.logger.info("Active workout: \(workout.id.uuidString)", category: .workout)
                } else {
                    self?.logger.info("No active workout", category: .workout)
                }
            }
            .store(in: &cancellables)

        // Observe permission state changes via PermissionManager
        setupPermissionMonitoring()
    }

    private func setupPermissionMonitoring() {
        // Monitor location permission changes
        permissionManager.locationStatePublisher
            .map { $0.isAuthorized }
            .removeDuplicates()
            .sink { [weak self] isAuthorized in
                self?.updateLocationAuthorization(authorized: isAuthorized)
            }
            .store(in: &cancellables)

        // Monitor motion permission changes
        permissionManager.motionStatePublisher
            .map { $0.isAuthorized }
            .removeDuplicates()
            .sink { [weak self] isAuthorized in
                self?.updateMotionAuthorization(authorized: isAuthorized)
            }
            .store(in: &cancellables)

        // Monitor HealthKit permission changes
        permissionManager.healthKitStatePublisher
            .map { $0.isAuthorized }
            .removeDuplicates()
            .sink { [weak self] isAuthorized in
                self?.updateHealthKitAuthorization(authorized: isAuthorized)
            }
            .store(in: &cancellables)
    }

    // MARK: - Permission Management

    /// Access to the permission manager for requesting permissions
    var permissions: PermissionManager {
        permissionManager
    }

    /// Updates location authorization status
    func updateLocationAuthorization(authorized: Bool) {
        isLocationAuthorized = authorized
        // Check if we have background location (Always authorization)
        let locationState = permissionManager.checkLocationPermission()
        isBackgroundLocationAuthorized = locationState == .authorized
        logger.info("Location authorization: \(authorized)", category: .permissions)
    }

    /// Updates background location authorization status
    func updateBackgroundLocationAuthorization(authorized: Bool) {
        isBackgroundLocationAuthorized = authorized
        logger.info("Background location authorization: \(authorized)", category: .permissions)
    }

    /// Updates motion authorization status
    func updateMotionAuthorization(authorized: Bool) {
        isMotionAuthorized = authorized
        logger.info("Motion authorization: \(authorized)", category: .permissions)
    }

    /// Updates HealthKit authorization status
    func updateHealthKitAuthorization(authorized: Bool) {
        isHealthKitAuthorized = authorized
        settings.healthKitEnabled = authorized
        logger.info("HealthKit authorization: \(authorized)", category: .permissions)
    }

    /// Refreshes all permission states from the system
    func refreshPermissionStates() {
        _ = permissionManager.checkLocationPermission()
        _ = permissionManager.checkMotionPermission()
        _ = permissionManager.checkHealthKitPermission()
    }

    /// Checks if all required permissions are granted
    var hasRequiredPermissions: Bool {
        isLocationAuthorized
    }

    /// Checks if all recommended permissions are granted
    var hasRecommendedPermissions: Bool {
        isLocationAuthorized && isBackgroundLocationAuthorized && isMotionAuthorized
    }

    // MARK: - Workout Management

    /// Sets the active workout
    func setActiveWorkout(_ workout: ActiveWorkout?) {
        activeWorkout = workout
    }

    /// Checks if a workout is currently active
    var isWorkoutActive: Bool {
        activeWorkout != nil
    }

    // MARK: - Error Handling

    /// Sets the current error to be displayed
    func setError(_ error: AppError) {
        currentError = error

        // Log the error if needed
        if error.shouldLog {
            switch error.logLevel {
            case .info:
                logger.info(error.errorDescription ?? "Unknown error", category: .general)
            case .warning:
                logger.warning(error.errorDescription ?? "Unknown error", category: .general)
            case .error:
                logger.error(error.errorDescription ?? "Unknown error", category: .general)
            }
        }
    }

    /// Clears the current error
    func clearError() {
        currentError = nil
    }

    // MARK: - Loading State

    /// Sets the app-wide loading state
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    // MARK: - Background State

    /// Called when app enters background
    func didEnterBackground() {
        isInBackground = true
        logger.info("App entered background", category: .general)
    }

    /// Called when app enters foreground
    func didEnterForeground() {
        isInBackground = false
        logger.info("App entered foreground", category: .general)
    }

    // MARK: - Debug & Testing

    /// Resets app state (useful for testing)
    func reset() {
        isLocationAuthorized = false
        isBackgroundLocationAuthorized = false
        isMotionAuthorized = false
        isHealthKitAuthorized = false
        activeWorkout = nil
        currentError = nil
        isLoading = false
        logger.info("App state reset", category: .general)
    }
}

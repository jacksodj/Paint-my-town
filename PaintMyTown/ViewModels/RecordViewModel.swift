//
//  RecordViewModel.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

/// ViewModel for the Record view handling workout tracking state and UI updates
@MainActor
final class RecordViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current workout tracking state
    @Published var trackingState: TrackingState = .stopped

    /// Current distance in meters
    @Published var currentDistance: Double = 0

    /// Current duration in seconds
    @Published var currentDuration: TimeInterval = 0

    /// Current pace in seconds per km (nil if not available)
    @Published var currentPace: Double?

    /// Current speed in m/s (nil if not available)
    @Published var currentSpeed: Double?

    /// Current elevation gain in meters
    @Published var currentElevationGain: Double = 0

    /// Current route coordinates for map display
    @Published var currentRoute: [CLLocationCoordinate2D] = []

    /// Current user location
    @Published var currentLocation: CLLocation?

    /// Selected activity type
    @Published var selectedActivityType: ActivityType = .run

    /// Show confirmation alert for stopping workout
    @Published var showStopConfirmation: Bool = false

    /// Show workout summary sheet
    @Published var showWorkoutSummary: Bool = false

    /// Completed workout for summary
    @Published var completedWorkout: Activity?

    /// Error message to display
    @Published var errorMessage: String?

    /// Whether screen lock is disabled
    @Published var isScreenLockDisabled: Bool = false

    // MARK: - Private Properties

    private let workoutService: WorkoutServiceProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(workoutService: WorkoutServiceProtocol, locationService: LocationServiceProtocol) {
        self.workoutService = workoutService
        self.locationService = locationService

        setupSubscriptions()
    }

    convenience init() {
        let container = DependencyContainer.shared
        let workoutService = container.resolve(WorkoutServiceProtocol.self)
        let locationService = container.resolve(LocationServiceProtocol.self)
        self.init(workoutService: workoutService, locationService: locationService)
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to location updates
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // Subscribe to workout updates
        workoutService.activeWorkoutPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workout in
                self?.handleWorkoutUpdate(workout)
            }
            .store(in: &cancellables)

        // Subscribe to metrics updates
        workoutService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.handleMetricsUpdate(metrics)
            }
            .store(in: &cancellables)

        // Subscribe to tracking state
        locationService.locationPublisher
            .map { _ in self.locationService.trackingState }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$trackingState)
    }

    // MARK: - Public Methods

    /// Start a new workout
    func startWorkout() {
        guard locationService.isAuthorized else {
            errorMessage = "Location permission is required to track workouts"
            return
        }

        do {
            let workout = try workoutService.startWorkout(type: selectedActivityType)
            Logger.shared.info("Started workout: \(workout.type.rawValue)", category: .ui)

            // Enable screen lock prevention
            setScreenLockDisabled(true)

            // Provide haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
            Logger.shared.error("Failed to start workout", error: error, category: .ui)
        }
    }

    /// Pause the current workout
    func pauseWorkout() {
        do {
            try workoutService.pauseWorkout()
            Logger.shared.info("Paused workout", category: .ui)

            // Provide haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            errorMessage = "Failed to pause workout: \(error.localizedDescription)"
            Logger.shared.error("Failed to pause workout", error: error, category: .ui)
        }
    }

    /// Resume the paused workout
    func resumeWorkout() {
        do {
            try workoutService.resumeWorkout()
            Logger.shared.info("Resumed workout", category: .ui)

            // Provide haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = "Failed to resume workout: \(error.localizedDescription)"
            Logger.shared.error("Failed to resume workout", error: error, category: .ui)
        }
    }

    /// Request to stop the workout (shows confirmation)
    func requestStopWorkout() {
        showStopConfirmation = true
    }

    /// Stop and save the workout
    func stopWorkout() {
        Task {
            do {
                let activity = try await workoutService.endWorkout()
                completedWorkout = activity
                showWorkoutSummary = true
                resetState()

                Logger.shared.info("Stopped and saved workout", category: .ui)

                // Provide haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = "Failed to save workout: \(error.localizedDescription)"
                Logger.shared.error("Failed to save workout: \(error)", category: .ui)

                // Provide error haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    /// Cancel the workout without saving
    func cancelWorkout() {
        do {
            try workoutService.cancelWorkout()
            resetState()

            Logger.shared.info("Cancelled workout", category: .ui)

            // Provide haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } catch {
            errorMessage = "Failed to cancel workout: \(error.localizedDescription)"
            Logger.shared.error("Failed to cancel workout", error: error, category: .ui)
        }
    }

    /// Dismiss the workout summary
    func dismissSummary() {
        showWorkoutSummary = false
        completedWorkout = nil
    }

    // MARK: - Private Methods

    private func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location

        // Update route
        let coordinate = location.coordinate
        if !currentRoute.contains(where: { $0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude }) {
            currentRoute.append(coordinate)
        }
    }

    private func handleWorkoutUpdate(_ workout: ActiveWorkout?) {
        if workout == nil {
            // Workout ended or cancelled
            trackingState = .stopped
        }
    }

    private func handleMetricsUpdate(_ metrics: WorkoutMetrics) {
        currentDistance = metrics.distance
        currentDuration = metrics.movingTime
        currentPace = metrics.currentPace ?? metrics.averagePace
        currentSpeed = metrics.currentSpeed ?? metrics.averageSpeed
        currentElevationGain = metrics.elevationGain
    }

    private func handleSplitAnnouncement(_ split: Split) {
        // This will be handled by the audio feedback component
        Logger.shared.info("Split completed", category: .workout)
    }

    private func resetState() {
        currentDistance = 0
        currentDuration = 0
        currentPace = nil
        currentSpeed = nil
        currentElevationGain = 0
        currentRoute = []
        currentLocation = nil
        trackingState = .stopped

        // Re-enable screen lock
        setScreenLockDisabled(false)
    }

    private func setScreenLockDisabled(_ disabled: Bool) {
        isScreenLockDisabled = disabled
        UIApplication.shared.isIdleTimerDisabled = disabled
    }

    // MARK: - Computed Properties

    /// Formatted distance string
    var formattedDistance: String {
        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        let convertedDistance = currentDistance / distanceUnit.metersPerUnit
        return String(format: "%.2f", convertedDistance)
    }

    /// Distance unit abbreviation
    var distanceUnit: String {
        UserDefaultsManager.shared.distanceUnit.abbreviation
    }

    /// Formatted duration string (MM:SS or HH:MM:SS)
    var formattedDuration: String {
        let hours = Int(currentDuration) / 3600
        let minutes = (Int(currentDuration) % 3600) / 60
        let seconds = Int(currentDuration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Formatted pace string (min/km or min/mi)
    var formattedPace: String {
        guard let pace = currentPace else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Pace unit
    var paceUnit: String {
        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        return "/\(distanceUnit.abbreviation)"
    }

    /// Formatted elevation string
    var formattedElevation: String {
        String(format: "%.0f m", currentElevationGain)
    }

    /// Whether workout is currently active
    var isWorkoutActive: Bool {
        trackingState != .stopped
    }

    /// Whether workout is paused
    var isWorkoutPaused: Bool {
        guard let workout = workoutService.activeWorkout else { return false }
        return workout.isPaused
    }
}

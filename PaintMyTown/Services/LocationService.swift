//
//  LocationService.swift
//  PaintMyTown
//
//  Service for managing GPS location tracking during workouts
//  Comprehensive implementation for M1-T01 through M1-T09
//  Features: GPS filtering, Kalman smoothing, background tracking, battery optimization
//

import Foundation
import CoreLocation
import Combine

/// Service for managing GPS location tracking during workouts
/// Features: GPS filtering, smoothing, background tracking, battery optimization
@MainActor
final class LocationService: NSObject, LocationServiceProtocol {
    // MARK: - Dependencies

    private let permissionManager: PermissionManagerProtocol

    // MARK: - Core Properties

    private let manager: CLLocationManager
    private var locationFilter: LocationFilter
    private var locationSmoother: LocationSmoother
    private var currentConfig: LocationTrackingConfig

    // MARK: - State Properties

    @Published private(set) var trackingState: TrackingState = .stopped
    @Published private(set) var currentLocation: CLLocation?
    private var _authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Publishers

    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let trackingStateSubject = CurrentValueSubject<TrackingState, Never>(.stopped)
    private let authorizationSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<LocationError, Never>()

    // MARK: - Continuations

    private var authorizationContinuation: CheckedContinuation<PermissionState, Never>?

    // MARK: - Initialization

    init(permissionManager: PermissionManagerProtocol = PermissionManager()) {
        self.permissionManager = permissionManager
        self.manager = CLLocationManager()

        // Initialize with default config
        self.currentConfig = LocationTrackingConfig.standard(for: .walk)
        self.locationFilter = LocationFilter.filter(for: .walk)
        self.locationSmoother = LocationSmoother.smoother(for: .walk)

        super.init()

        setupLocationManager()
        updateAuthorizationStatus()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        manager.delegate = self

        // Configure for background updates
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true

        // Apply default configuration
        applyConfiguration(currentConfig)

        Logger.shared.info("LocationService initialized", category: .location)
    }

    private func applyConfiguration(_ config: LocationTrackingConfig) {
        // Set desired accuracy
        if config.desiredAccuracy < 0 {
            // Use special constants
            if config.desiredAccuracy == -1 {
                manager.desiredAccuracy = kCLLocationAccuracyBest
            } else if config.desiredAccuracy == -2 {
                manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            }
        } else {
            manager.desiredAccuracy = config.desiredAccuracy
        }

        // Set distance filter (minimum distance before update)
        manager.distanceFilter = config.distanceFilter

        // Set activity type based on activity
        switch config.activityType {
        case .walk, .run:
            manager.activityType = .fitness
        case .bike:
            manager.activityType = .otherNavigation
        }

        // Configure background updates
        manager.pausesLocationUpdatesAutomatically = config.pausesAutomatically

        // Enable background location updates if supported
        if config.allowsBackgroundUpdates {
            manager.allowsBackgroundLocationUpdates = true
        }

        Logger.shared.info("Applied location config: accuracy=\(config.desiredAccuracy), filter=\(config.distanceFilter)m", category: .location)
    }

    // MARK: - LocationServiceProtocol - State Properties

    var authorizationStatus: CLAuthorizationStatus {
        return _authorizationStatus
    }

    var isAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var isTracking: Bool {
        return trackingState == .active
    }

    // MARK: - LocationServiceProtocol - Publishers

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var trackingStatePublisher: AnyPublisher<TrackingState, Never> {
        trackingStateSubject.eraseToAnyPublisher()
    }

    var authorizationPublisher: AnyPublisher<Bool, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<LocationError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - LocationServiceProtocol - Tracking Control

    func startTracking(config: LocationTrackingConfig) async throws {
        Logger.shared.info("Starting location tracking with config", category: .location)

        // Check authorization
        guard isAuthorized else {
            let error = LocationError.notAuthorized
            errorSubject.send(error)
            throw error
        }

        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            let error = LocationError.locationServicesDisabled
            errorSubject.send(error)
            throw error
        }

        // Update configuration
        currentConfig = config
        applyConfiguration(config)

        // Reset filter and smoother for new tracking session
        locationFilter = LocationFilter.filter(for: config.activityType)
        locationSmoother = LocationSmoother.smoother(for: config.activityType)

        // Start location updates
        manager.startUpdatingLocation()

        // Update state
        trackingState = .active
        trackingStateSubject.send(.active)

        Logger.shared.info("Location tracking started for \(config.activityType.rawValue)", category: .location)
    }

    func startTracking(activityType: ActivityType) throws {
        Logger.shared.info("Starting location tracking for \(activityType.rawValue)", category: .location)

        // Check authorization synchronously
        guard isAuthorized else {
            let error = LocationError.notAuthorized
            errorSubject.send(error)
            Logger.shared.warning("Cannot start tracking: location not authorized", category: .location)
            throw error
        }

        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            let error = LocationError.locationServicesDisabled
            errorSubject.send(error)
            throw error
        }

        // Create standard config for activity type
        let config = LocationTrackingConfig.standard(for: activityType)
        currentConfig = config
        applyConfiguration(config)

        // Reset filter and smoother for new tracking session
        locationFilter = LocationFilter.filter(for: activityType)
        locationSmoother = LocationSmoother.smoother(for: activityType)

        // Start location updates
        manager.startUpdatingLocation()

        // Update state
        trackingState = .active
        trackingStateSubject.send(.active)

        Logger.shared.info("Location tracking started", category: .location)
    }

    func pauseTracking() {
        guard trackingState == .active else { return }

        trackingState = .paused
        trackingStateSubject.send(.paused)

        Logger.shared.info("Location tracking paused", category: .location)
    }

    func resumeTracking() {
        guard trackingState == .paused else { return }

        trackingState = .active
        trackingStateSubject.send(.active)

        Logger.shared.info("Location tracking resumed", category: .location)
    }

    func stopTracking() {
        guard trackingState != .stopped else { return }

        manager.stopUpdatingLocation()
        trackingState = .stopped
        trackingStateSubject.send(.stopped)
        currentLocation = nil

        Logger.shared.info("Location tracking stopped", category: .location)
    }

    // MARK: - LocationServiceProtocol - Configuration

    func updateConfiguration(_ config: LocationTrackingConfig) {
        currentConfig = config
        applyConfiguration(config)

        // Update filter and smoother for new config
        locationFilter = LocationFilter.filter(for: config.activityType)
        locationSmoother = LocationSmoother.smoother(for: config.activityType)

        Logger.shared.info("Location configuration updated", category: .location)
    }

    func requestAlwaysAuthorization() async -> PermissionState {
        return await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation

            let status = manager.authorizationStatus
            if status == .authorizedAlways {
                continuation.resume(returning: .authorized)
                self.authorizationContinuation = nil
            } else if status == .authorizedWhenInUse {
                // Request upgrade to always
                manager.requestAlwaysAuthorization()
            } else {
                // Not authorized yet
                continuation.resume(returning: PermissionState(from: status))
                self.authorizationContinuation = nil
            }
        }
    }

    // MARK: - LocationServiceProtocol - Statistics

    func getFilterStatistics() -> FilterStatistics {
        return locationFilter.statistics()
    }

    func getSmootherStatistics() -> SmootherStatistics {
        return locationSmoother.statistics()
    }

    func resetStatistics() {
        locationFilter.reset()
        locationSmoother.reset()
        Logger.shared.info("Location statistics reset", category: .location)
    }

    // MARK: - AuthorizableServiceProtocol

    func initialize() async throws {
        updateAuthorizationStatus()
    }

    func cleanup() {
        stopTracking()
    }

    func requestAuthorization() async throws -> Bool {
        let state = await permissionManager.requestLocationPermission()
        return state.isAuthorized
    }

    func checkAuthorization() async -> Bool {
        return isAuthorized
    }

    // MARK: - Private Methods

    private func updateAuthorizationStatus() {
        _authorizationStatus = manager.authorizationStatus
        let authorized = isAuthorized
        authorizationSubject.send(authorized)

        Logger.shared.info("Location authorization status: \(_authorizationStatus.rawValue), authorized: \(authorized)", category: .location)
    }

    private nonisolated func processLocation(_ location: CLLocation) async {
        await MainActor.run {
            // Apply filter
            let filterResult = locationFilter.shouldAccept(location)

            guard filterResult.isAccepted else {
                if let reason = filterResult.rejectionReason {
                    Logger.shared.debug("Location rejected: \(reason.description)", category: .location)
                }
                return
            }

            // Apply smoothing (Kalman filter)
            let smoothedLocation = locationSmoother.smooth(location)

            // Update current location
            currentLocation = smoothedLocation

            // Publish to subscribers
            locationSubject.send(smoothedLocation)

            Logger.shared.debug(
                "Location: lat=\(String(format: "%.6f", smoothedLocation.coordinate.latitude)), lon=\(String(format: "%.6f", smoothedLocation.coordinate.longitude)), acc=\(String(format: "%.1f", smoothedLocation.horizontalAccuracy))m",
                category: .location
            )
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            await MainActor.run {
                // Only process locations when actively tracking
                guard trackingState == .active else { return }

                // Process each location
                for location in locations {
                    Task {
                        await processLocation(location)
                    }
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await MainActor.run {
                Logger.shared.error("Location manager error: \(error.localizedDescription)", category: .location)

                let locationError: LocationError
                if let clError = error as? CLError {
                    switch clError.code {
                    case .denied:
                        locationError = .denied
                    case .locationUnknown:
                        locationError = .unknown("Location unknown")
                    default:
                        locationError = .unknown(error.localizedDescription)
                    }
                } else {
                    locationError = .unknown(error.localizedDescription)
                }

                errorSubject.send(locationError)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            await MainActor.run {
                updateAuthorizationStatus()

                // Resume continuation if waiting
                if let continuation = authorizationContinuation {
                    authorizationContinuation = nil
                    continuation.resume(returning: PermissionState(from: manager.authorizationStatus))
                }

                // Notify app state
                if isAuthorized {
                    AppState.shared.updateLocationAuthorization(authorized: true)
                } else {
                    AppState.shared.updateLocationAuthorization(authorized: false)
                }
            }
        }
    }
}

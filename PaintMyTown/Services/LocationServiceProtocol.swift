//
//  LocationServiceProtocol.swift
//  PaintMyTown
//
//  Protocol defining location tracking capabilities
//  Enhanced as part of M1-T01 through M1-T09
//

import Foundation
import CoreLocation
import Combine

/// Protocol defining location tracking service capabilities
/// Conforms to ServiceProtocol patterns for consistency
protocol LocationServiceProtocol: AuthorizableServiceProtocol {
    // MARK: - State Properties

    /// Current location (most recent valid location)
    var currentLocation: CLLocation? { get }

    /// Current tracking state
    var trackingState: TrackingState { get }

    /// Location authorization status
    var authorizationStatus: CLAuthorizationStatus { get }

    /// Whether the service is actively tracking
    var isTracking: Bool { get }

    // MARK: - Publishers

    /// Publisher for location updates (filtered and smoothed)
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }

    /// Publisher for tracking state changes
    var trackingStatePublisher: AnyPublisher<TrackingState, Never> { get }

    /// Publisher for authorization status changes
    var authorizationPublisher: AnyPublisher<Bool, Never> { get }

    /// Publisher for location errors
    var errorPublisher: AnyPublisher<LocationError, Never> { get }

    // MARK: - Tracking Control

    /// Start tracking with the specified configuration
    /// - Parameter config: Configuration for tracking accuracy and battery usage
    /// - Throws: LocationError if tracking cannot be started
    func startTracking(config: LocationTrackingConfig) async throws

    /// Start tracking for a specific activity type (convenience method)
    /// - Parameter activityType: The type of activity to optimize tracking for
    /// - Throws: LocationError if tracking cannot be started
    func startTracking(activityType: ActivityType) throws

    /// Pause location tracking (keeps manager active but doesn't record)
    func pauseTracking()

    /// Resume location tracking after pause
    func resumeTracking()

    /// Stop location tracking completely
    func stopTracking()

    // MARK: - Configuration

    /// Update the tracking configuration (e.g., change accuracy)
    /// - Parameter config: New configuration to apply
    func updateConfiguration(_ config: LocationTrackingConfig)

    /// Request "Always" authorization explicitly (for background tracking)
    func requestAlwaysAuthorization() async -> PermissionState

    // MARK: - Statistics

    /// Get filter statistics
    func getFilterStatistics() -> FilterStatistics

    /// Get smoother statistics
    func getSmootherStatistics() -> SmootherStatistics

    /// Reset statistics
    func resetStatistics()
}

/// Errors that can occur during location tracking
enum LocationError: LocalizedError, Equatable {
    case notAuthorized
    case restricted
    case denied
    case locationServicesDisabled
    case backgroundUpdatesNotAvailable
    case accuracyReduced
    case failedToStart(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access has not been authorized. Please grant permission in Settings."
        case .restricted:
            return "Location access is restricted on this device."
        case .denied:
            return "Location access was denied. Please enable it in Settings."
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .backgroundUpdatesNotAvailable:
            return "Background location updates are not available on this device."
        case .accuracyReduced:
            return "Location accuracy is reduced. Grant precise location access for better tracking."
        case .failedToStart(let message):
            return "Failed to start location tracking: \(message)"
        case .unknown(let message):
            return "Location error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized, .denied:
            return "Go to Settings > Privacy > Location Services and enable access for Paint the Town."
        case .restricted:
            return "Location access is managed by restrictions. Contact your device administrator."
        case .locationServicesDisabled:
            return "Enable Location Services in Settings > Privacy > Location Services."
        case .backgroundUpdatesNotAvailable:
            return "Background tracking requires a device with GPS capabilities."
        case .accuracyReduced:
            return "Go to Settings > Privacy > Location Services > Paint the Town and select 'Precise Location'."
        case .failedToStart, .unknown:
            return "Try restarting the app or your device."
        }
    }
}

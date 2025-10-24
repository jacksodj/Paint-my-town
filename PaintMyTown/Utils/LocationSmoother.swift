//
//  LocationSmoother.swift
//  PaintMyTown
//
//  Location smoothing utility using Kalman filter
//  Reduces GPS jitter while maintaining accuracy
//  Implemented as part of M1-T05 (Location smoothing algorithm)
//

import Foundation
import CoreLocation

/// Smooths GPS location data using a Kalman filter to reduce jitter
/// while maintaining responsiveness to actual movement
class LocationSmoother {
    // MARK: - Kalman Filter Parameters

    /// Process noise (how much we trust the model vs measurements)
    /// Higher values = more responsive to changes, less smoothing
    private let processNoise: Double

    /// Measurement noise (GPS accuracy uncertainty)
    private let measurementNoise: Double

    // MARK: - State Variables

    /// Current estimated latitude
    private var estimatedLatitude: Double?

    /// Current estimated longitude
    private var estimatedLongitude: Double?

    /// Current estimated altitude
    private var estimatedAltitude: Double?

    /// Estimation error covariance for latitude
    private var errorCovarianceLat: Double = 1.0

    /// Estimation error covariance for longitude
    private var errorCovarianceLon: Double = 1.0

    /// Estimation error covariance for altitude
    private var errorCovarianceAlt: Double = 1.0

    /// Last smoothed location
    private var lastSmoothedLocation: CLLocation?

    /// Number of locations processed
    private var locationsProcessed: Int = 0

    // MARK: - Initialization

    /// Initialize location smoother with Kalman filter
    /// - Parameters:
    ///   - processNoise: Process noise parameter (default: 0.01)
    ///   - measurementNoise: Measurement noise parameter (default: 1.0)
    init(processNoise: Double = 0.01, measurementNoise: Double = 1.0) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
    }

    /// Create smoother configured for specific activity type
    /// - Parameter activityType: The type of activity being tracked
    /// - Returns: Configured LocationSmoother instance
    static func smoother(for activityType: ActivityType) -> LocationSmoother {
        switch activityType {
        case .walk:
            // More smoothing for walking (slower movement)
            return LocationSmoother(processNoise: 0.008, measurementNoise: 1.0)
        case .run:
            // Balanced smoothing for running
            return LocationSmoother(processNoise: 0.01, measurementNoise: 1.0)
        case .bike:
            // Less smoothing for biking (faster movement)
            return LocationSmoother(processNoise: 0.015, measurementNoise: 1.0)
        }
    }

    // MARK: - Smoothing

    /// Smooth a location using Kalman filter
    /// - Parameter location: The raw location to smooth
    /// - Returns: Smoothed location
    func smooth(_ location: CLLocation) -> CLLocation {
        locationsProcessed += 1

        // First location - initialize filter
        guard let estLat = estimatedLatitude,
              let estLon = estimatedLongitude,
              let estAlt = estimatedAltitude else {
            // Initialize with first location
            estimatedLatitude = location.coordinate.latitude
            estimatedLongitude = location.coordinate.longitude
            estimatedAltitude = location.altitude
            errorCovarianceLat = location.horizontalAccuracy
            errorCovarianceLon = location.horizontalAccuracy
            errorCovarianceAlt = location.verticalAccuracy
            lastSmoothedLocation = location
            return location
        }

        // Kalman filter update for latitude
        let smoothedLat = kalmanUpdate(
            currentEstimate: estLat,
            measurement: location.coordinate.latitude,
            errorCovariance: &errorCovarianceLat,
            measurementAccuracy: location.horizontalAccuracy
        )

        // Kalman filter update for longitude
        let smoothedLon = kalmanUpdate(
            currentEstimate: estLon,
            measurement: location.coordinate.longitude,
            errorCovariance: &errorCovarianceLon,
            measurementAccuracy: location.horizontalAccuracy
        )

        // Kalman filter update for altitude
        let smoothedAlt = kalmanUpdate(
            currentEstimate: estAlt,
            measurement: location.altitude,
            errorCovariance: &errorCovarianceAlt,
            measurementAccuracy: max(location.verticalAccuracy, 1.0)
        )

        // Update state
        estimatedLatitude = smoothedLat
        estimatedLongitude = smoothedLon
        estimatedAltitude = smoothedAlt

        // Create smoothed location
        let smoothedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: smoothedLat,
                longitude: smoothedLon
            ),
            altitude: smoothedAlt,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            course: location.course,
            speed: location.speed,
            timestamp: location.timestamp
        )

        lastSmoothedLocation = smoothedLocation
        return smoothedLocation
    }

    /// Kalman filter update step
    /// - Parameters:
    ///   - currentEstimate: Current estimated value
    ///   - measurement: New measurement
    ///   - errorCovariance: Error covariance (will be updated)
    ///   - measurementAccuracy: Accuracy of the measurement
    /// - Returns: Updated estimate
    private func kalmanUpdate(
        currentEstimate: Double,
        measurement: Double,
        errorCovariance: inout Double,
        measurementAccuracy: Double
    ) -> Double {
        // Prediction step
        // Predict error covariance
        let predictedErrorCovariance = errorCovariance + processNoise

        // Update step
        // Calculate Kalman gain
        let measurementVariance = max(measurementAccuracy * measurementAccuracy, measurementNoise)
        let kalmanGain = predictedErrorCovariance / (predictedErrorCovariance + measurementVariance)

        // Update estimate with measurement
        let innovation = measurement - currentEstimate
        let updatedEstimate = currentEstimate + kalmanGain * innovation

        // Update error covariance
        errorCovariance = (1.0 - kalmanGain) * predictedErrorCovariance

        return updatedEstimate
    }

    /// Reset the smoother state (call when starting new workout)
    func reset() {
        estimatedLatitude = nil
        estimatedLongitude = nil
        estimatedAltitude = nil
        errorCovarianceLat = 1.0
        errorCovarianceLon = 1.0
        errorCovarianceAlt = 1.0
        lastSmoothedLocation = nil
        locationsProcessed = 0
    }

    /// Get the last smoothed location
    var lastLocation: CLLocation? {
        return lastSmoothedLocation
    }

    /// Get smoother statistics
    func statistics() -> SmootherStatistics {
        SmootherStatistics(
            locationsProcessed: locationsProcessed,
            currentErrorCovarianceLat: errorCovarianceLat,
            currentErrorCovarianceLon: errorCovarianceLon,
            currentErrorCovarianceAlt: errorCovarianceAlt
        )
    }
}

// MARK: - Supporting Types

/// Statistics about location smoothing
struct SmootherStatistics {
    let locationsProcessed: Int
    let currentErrorCovarianceLat: Double
    let currentErrorCovarianceLon: Double
    let currentErrorCovarianceAlt: Double

    var averageErrorCovariance: Double {
        return (currentErrorCovarianceLat + currentErrorCovarianceLon) / 2.0
    }
}

// MARK: - Alternative: Moving Average Smoother

/// Simple moving average smoother (alternative to Kalman filter)
/// Averages the last N locations for smoothing
class MovingAverageSmoother {
    private let windowSize: Int
    private var locationWindow: [CLLocation] = []

    init(windowSize: Int = 5) {
        self.windowSize = max(1, windowSize)
    }

    func smooth(_ location: CLLocation) -> CLLocation {
        // Add to window
        locationWindow.append(location)

        // Keep only last N locations
        if locationWindow.count > windowSize {
            locationWindow.removeFirst()
        }

        // Average the locations
        guard locationWindow.count > 0 else {
            return location
        }

        let avgLat = locationWindow.map { $0.coordinate.latitude }.reduce(0, +) / Double(locationWindow.count)
        let avgLon = locationWindow.map { $0.coordinate.longitude }.reduce(0, +) / Double(locationWindow.count)
        let avgAlt = locationWindow.map { $0.altitude }.reduce(0, +) / Double(locationWindow.count)

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            altitude: avgAlt,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            course: location.course,
            speed: location.speed,
            timestamp: location.timestamp
        )
    }

    func reset() {
        locationWindow.removeAll()
    }
}

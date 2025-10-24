//
//  LocationSmootherTests.swift
//  PaintMyTownTests
//
//  Unit tests for LocationSmoother utility
//  Tests for M1-T05 (Location smoothing algorithm)
//

import XCTest
import CoreLocation
@testable import PaintMyTown

final class LocationSmootherTests: XCTestCase {
    var sut: LocationSmoother!

    override func setUp() {
        super.setUp()
        sut = LocationSmoother()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // When
        let stats = sut.statistics()

        // Then
        XCTAssertEqual(stats.locationsProcessed, 0)
    }

    // MARK: - Smoothing Tests

    func testFirstLocationPassthrough() {
        // Given
        let location = createLocation(latitude: 37.7749, longitude: -122.4194)

        // When
        let smoothed = sut.smooth(location)

        // Then
        XCTAssertEqual(smoothed.coordinate.latitude, location.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(smoothed.coordinate.longitude, location.coordinate.longitude, accuracy: 0.0001)
    }

    func testSmoothing ReducesJitter() {
        // Given - locations with slight GPS jitter
        let baseLocation = createLocation(latitude: 37.7749, longitude: -122.4194)
        let jitteredLocation1 = createLocation(latitude: 37.77491, longitude: -122.41941)
        let jitteredLocation2 = createLocation(latitude: 37.77489, longitude: -122.41939)

        // When
        let smoothed1 = sut.smooth(baseLocation)
        let smoothed2 = sut.smooth(jitteredLocation1)
        let smoothed3 = sut.smooth(jitteredLocation2)

        // Then - smoothed locations should vary less than raw locations
        let rawVariation = abs(jitteredLocation1.coordinate.latitude - baseLocation.coordinate.latitude)
        let smoothedVariation = abs(smoothed2.coordinate.latitude - smoothed1.coordinate.latitude)

        XCTAssertLessThan(smoothedVariation, rawVariation)
    }

    func testSmoothingMaintainsTimestamp() {
        // Given
        let timestamp = Date()
        let location = createLocation(timestamp: timestamp)

        // When
        let smoothed = sut.smooth(location)

        // Then
        XCTAssertEqual(smoothed.timestamp, timestamp)
    }

    func testSmoothingMaintainsAccuracy() {
        // Given
        let accuracy: CLLocationAccuracy = 15.0
        let location = createLocation(accuracy: accuracy)

        // When
        let smoothed = sut.smooth(location)

        // Then
        XCTAssertEqual(smoothed.horizontalAccuracy, accuracy)
    }

    // MARK: - Activity-Specific Smoothers Tests

    func testWalkingSmoother() {
        // Given
        let smoother = LocationSmoother.smoother(for: .walk)

        // When
        let location = createLocation()
        let smoothed = smoother.smooth(location)

        // Then
        XCTAssertNotNil(smoothed)
    }

    func testRunningSmoother() {
        // Given
        let smoother = LocationSmoother.smoother(for: .run)

        // When
        let location = createLocation()
        let smoothed = smoother.smooth(location)

        // Then
        XCTAssertNotNil(smoothed)
    }

    func testBikingSmoother() {
        // Given
        let smoother = LocationSmoother.smoother(for: .bike)

        // When
        let location = createLocation()
        let smoothed = smoother.smooth(location)

        // Then
        XCTAssertNotNil(smoothed)
    }

    // MARK: - Statistics Tests

    func testStatistics() {
        // Given
        let location1 = createLocation()
        let location2 = createLocation(latitude: 37.7750)

        // When
        _ = sut.smooth(location1)
        _ = sut.smooth(location2)

        let stats = sut.statistics()

        // Then
        XCTAssertEqual(stats.locationsProcessed, 2)
        XCTAssertGreaterThan(stats.currentErrorCovarianceLat, 0)
        XCTAssertGreaterThan(stats.currentErrorCovarianceLon, 0)
    }

    func testReset() {
        // Given
        let location = createLocation()
        _ = sut.smooth(location)

        // When
        sut.reset()
        let stats = sut.statistics()

        // Then
        XCTAssertEqual(stats.locationsProcessed, 0)
    }

    func testLastLocation() {
        // Given
        let location1 = createLocation(latitude: 37.7749)
        let location2 = createLocation(latitude: 37.7750)

        // When
        _ = sut.smooth(location1)
        let smoothed2 = sut.smooth(location2)

        // Then
        XCTAssertNotNil(sut.lastLocation)
        XCTAssertEqual(sut.lastLocation?.coordinate.latitude, smoothed2.coordinate.latitude)
    }

    // MARK: - Kalman Filter Tests

    func testKalmanFilterConvergence() {
        // Given - series of locations at same position (simulating stationary with GPS noise)
        let baseLatitude = 37.7749
        let baseLongitude = -122.4194
        var smoothedLocations: [CLLocation] = []

        // When - add noisy measurements
        for i in 0..<20 {
            let noise = Double.random(in: -0.0001...0.0001)
            let location = createLocation(
                latitude: baseLatitude + noise,
                longitude: baseLongitude + noise
            )
            let smoothed = sut.smooth(location)
            smoothedLocations.append(smoothed)
        }

        // Then - variance should decrease over time (filter converging)
        if smoothedLocations.count >= 10 {
            let earlyVariance = calculateVariance(smoothedLocations.prefix(5).map { $0 })
            let lateVariance = calculateVariance(smoothedLocations.suffix(5).map { $0 })

            XCTAssertLessThan(lateVariance, earlyVariance)
        }
    }

    // MARK: - Moving Average Smoother Tests

    func testMovingAverageSmoother() {
        // Given
        let movingAvg = MovingAverageSmoother(windowSize: 3)
        let location1 = createLocation(latitude: 37.7749)
        let location2 = createLocation(latitude: 37.7750)
        let location3 = createLocation(latitude: 37.7751)

        // When
        let smoothed1 = movingAvg.smooth(location1)
        let smoothed2 = movingAvg.smooth(location2)
        let smoothed3 = movingAvg.smooth(location3)

        // Then - third smoothed location should be average of all three
        let expectedLat = (location1.coordinate.latitude + location2.coordinate.latitude + location3.coordinate.latitude) / 3.0
        XCTAssertEqual(smoothed3.coordinate.latitude, expectedLat, accuracy: 0.0001)
    }

    // MARK: - Helper Methods

    private func createLocation(
        latitude: CLLocationDegrees = 37.7749,
        longitude: CLLocationDegrees = -122.4194,
        accuracy: CLLocationAccuracy = 10.0,
        timestamp: Date = Date()
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 10,
            course: 0,
            speed: 1.0,
            timestamp: timestamp
        )
    }

    private func calculateVariance(_ locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0 }

        let mean = locations.map { $0.coordinate.latitude }.reduce(0, +) / Double(locations.count)
        let squaredDiffs = locations.map { pow($0.coordinate.latitude - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(locations.count)
    }
}

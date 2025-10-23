//
//  SplitCalculatorTests.swift
//  PaintMyTownTests
//
//  Created on 2025-10-23.
//

import XCTest
import CoreLocation
@testable import PaintMyTown

final class SplitCalculatorTests: XCTestCase {
    var sut: SplitCalculator!

    override func setUp() {
        super.setUp()
        sut = SplitCalculator(distanceUnit: .kilometers)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Split Calculation Tests

    func testProcessLocation_CompletesKilometerSplit() {
        // Given - Generate locations for 1km
        let locations = generateLocationsForDistance(1000) // 1000 meters

        // When
        var completedSplit: Split?
        for location in locations {
            if let split = sut.processLocation(location) {
                completedSplit = split
            }
        }

        // Then
        XCTAssertNotNil(completedSplit, "Should complete a 1km split")
        XCTAssertEqual(sut.completedSplits.count, 1)
        XCTAssertEqual(completedSplit?.distance, 1000, accuracy: 10)
    }

    func testProcessLocation_CompletesMultipleSplits() {
        // Given - Generate locations for 2.5km
        let locations = generateLocationsForDistance(2500)

        // When
        for location in locations {
            _ = sut.processLocation(location)
        }

        // Then
        XCTAssertEqual(sut.completedSplits.count, 2, "Should complete 2 full splits")
    }

    func testProcessLocation_CalculatesSplitPace() {
        // Given - Generate locations at consistent pace (5 min/km)
        let locations = generateLocationsForDistance(
            1000,
            interval: 15.0 // 50m every 15s = 200m/min = 5 min/km
        )

        // When
        var completedSplit: Split?
        for location in locations {
            if let split = sut.processLocation(location) {
                completedSplit = split
            }
        }

        // Then
        XCTAssertNotNil(completedSplit)
        // Pace should be around 300 seconds (5 minutes)
        XCTAssertEqual(completedSplit?.pace ?? 0, 300, accuracy: 30)
    }

    func testCurrentSplitProgress_ReturnsCorrectPercentage() {
        // Given
        let halfKmLocations = generateLocationsForDistance(500)

        // When
        for location in halfKmLocations {
            _ = sut.processLocation(location)
        }

        // Then
        let progress = sut.currentSplitProgress
        XCTAssertEqual(progress, 0.5, accuracy: 0.1)
    }

    func testDistanceRemainingInSplit_CalculatesCorrectly() {
        // Given
        let partialLocations = generateLocationsForDistance(300)

        // When
        for location in partialLocations {
            _ = sut.processLocation(location)
        }

        // Then
        let remaining = sut.distanceRemainingInSplit
        XCTAssertEqual(remaining, 700, accuracy: 50)
    }

    func testReset_ClearsState() {
        // Given
        let locations = generateLocationsForDistance(1500)
        for location in locations {
            _ = sut.processLocation(location)
        }

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.completedSplits.count, 0)
        XCTAssertEqual(sut.currentSplitProgress, 0)
        XCTAssertEqual(sut.distanceRemainingInSplit, 1000)
    }

    func testMileSplits_CompletesAtCorrectDistance() {
        // Given
        sut = SplitCalculator(distanceUnit: .miles)
        let oneMileInMeters = 1609.34
        let locations = generateLocationsForDistance(oneMileInMeters)

        // When
        var completedSplit: Split?
        for location in locations {
            if let split = sut.processLocation(location) {
                completedSplit = split
            }
        }

        // Then
        XCTAssertNotNil(completedSplit, "Should complete a 1 mile split")
        XCTAssertEqual(completedSplit?.distance, oneMileInMeters, accuracy: 10)
    }

    // MARK: - Elevation Tests

    func testElevationGain_TracksCorrectly() {
        // Given
        var locations: [CLLocation] = []
        let baseLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)

        // Generate 1km with elevation gain
        for i in 0..<20 {
            let distance = Double(i) * 50.0 // 50m increments
            let elevation = Double(i) * 5.0 // 5m elevation gain per segment
            let location = createLocation(
                from: baseLocation,
                distanceMeters: distance,
                altitude: elevation,
                timestamp: Date().addingTimeInterval(TimeInterval(i * 15))
            )
            locations.append(location)
        }

        // When
        var completedSplit: Split?
        for location in locations {
            if let split = sut.processLocation(location) {
                completedSplit = split
            }
        }

        // Then
        XCTAssertNotNil(completedSplit)
        XCTAssertGreaterThan(completedSplit?.elevationGain ?? 0, 50)
    }

    // MARK: - Helper Methods

    private func generateLocationsForDistance(
        _ distanceMeters: Double,
        interval: TimeInterval = 15.0
    ) -> [CLLocation] {
        var locations: [CLLocation] = []
        let baseLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let segmentDistance = 50.0 // 50 meters per segment
        let segmentCount = Int(ceil(distanceMeters / segmentDistance))

        for i in 0..<segmentCount {
            let distance = Double(i) * segmentDistance
            let location = createLocation(
                from: baseLocation,
                distanceMeters: distance,
                timestamp: Date().addingTimeInterval(TimeInterval(i) * interval)
            )
            locations.append(location)
        }

        return locations
    }

    private func createLocation(
        from baseLocation: CLLocation,
        distanceMeters: Double,
        altitude: Double = 0,
        timestamp: Date
    ) -> CLLocation {
        // Approximate: 1 degree latitude ≈ 111km
        let metersPerDegree = 111000.0
        let latitudeOffset = distanceMeters / metersPerDegree

        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: baseLocation.coordinate.latitude + latitudeOffset,
                longitude: baseLocation.coordinate.longitude
            ),
            altitude: altitude,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: timestamp
        )
    }
}

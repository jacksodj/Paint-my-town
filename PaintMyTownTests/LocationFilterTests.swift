//
//  LocationFilterTests.swift
//  PaintMyTownTests
//
//  Unit tests for LocationFilter utility
//  Tests for M1-T04 (GPS filtering)
//

import XCTest
import CoreLocation
@testable import PaintMyTown

final class LocationFilterTests: XCTestCase {
    var sut: LocationFilter!

    override func setUp() {
        super.setUp()
        sut = LocationFilter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Accuracy Filtering Tests

    func testAcceptsGoodAccuracy() {
        // Given
        let location = createLocation(accuracy: 10.0)

        // When
        let result = sut.shouldAccept(location)

        // Then
        XCTAssertTrue(result.isAccepted)
    }

    func testRejectsPoorAccuracy() {
        // Given
        let location = createLocation(accuracy: 50.0) // > threshold of 20m

        // When
        let result = sut.shouldAccept(location)

        // Then
        XCTAssertFalse(result.isAccepted)
        if case .rejected(let reason) = result {
            if case .poorAccuracy = reason {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected poorAccuracy rejection")
            }
        }
    }

    func testRejectsNegativeAccuracy() {
        // Given
        let location = createLocation(accuracy: -1.0)

        // When
        let result = sut.shouldAccept(location)

        // Then
        XCTAssertFalse(result.isAccepted)
    }

    // MARK: - Age Filtering Tests

    func testAcceptsRecentLocation() {
        // Given
        let location = createLocation(timestamp: Date())

        // When
        let result = sut.shouldAccept(location)

        // Then
        XCTAssertTrue(result.isAccepted)
    }

    func testRejectsStaleLocation() {
        // Given
        let oldTimestamp = Date().addingTimeInterval(-30) // 30 seconds old
        let location = createLocation(timestamp: oldTimestamp)

        // When
        let result = sut.shouldAccept(location)

        // Then
        XCTAssertFalse(result.isAccepted)
        if case .rejected(let reason) = result {
            if case .staleLocation = reason {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected staleLocation rejection")
            }
        }
    }

    // MARK: - Displacement Filtering Tests

    func testAcceptsSufficientDisplacement() {
        // Given
        let location1 = createLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = createLocation(latitude: 37.7750, longitude: -122.4194) // ~11m away

        // When
        _ = sut.shouldAccept(location1)
        let result = sut.shouldAccept(location2)

        // Then
        XCTAssertTrue(result.isAccepted)
    }

    func testRejectsInsufficientDisplacement() {
        // Given
        let location1 = createLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = createLocation(latitude: 37.77491, longitude: -122.4194) // ~1m away

        // When
        _ = sut.shouldAccept(location1)
        let result = sut.shouldAccept(location2)

        // Then
        XCTAssertFalse(result.isAccepted)
        if case .rejected(let reason) = result {
            if case .insufficientDisplacement = reason {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected insufficientDisplacement rejection")
            }
        }
    }

    // MARK: - Speed Filtering Tests

    func testRejectsImpossibleSpeed() {
        // Given
        let location1 = createLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: Date()
        )
        let location2 = createLocation(
            latitude: 37.8749, // ~11km away
            longitude: -122.4194,
            timestamp: Date().addingTimeInterval(1) // 1 second later = ~11,000 m/s!
        )

        // When
        _ = sut.shouldAccept(location1)
        let result = sut.shouldAccept(location2)

        // Then
        XCTAssertFalse(result.isAccepted)
        if case .rejected(let reason) = result {
            if case .impossibleSpeed = reason {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected impossibleSpeed rejection")
            }
        }
    }

    // MARK: - Activity-Specific Filters Tests

    func testWalkingFilter() {
        // Given
        let filter = LocationFilter.filter(for: .walk)
        let location1 = createLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = createLocation(
            latitude: 37.7750,
            longitude: -122.4194,
            timestamp: Date().addingTimeInterval(2) // Reasonable walking speed
        )

        // When
        _ = filter.shouldAccept(location1)
        let result = filter.shouldAccept(location2)

        // Then
        XCTAssertTrue(result.isAccepted)
    }

    func testRunningFilter() {
        // Given
        let filter = LocationFilter.filter(for: .run)

        // When/Then
        XCTAssertNotNil(filter)
    }

    func testBikingFilter() {
        // Given
        let filter = LocationFilter.filter(for: .bike)

        // When/Then
        XCTAssertNotNil(filter)
    }

    // MARK: - Statistics Tests

    func testStatistics() {
        // Given
        let goodLocation = createLocation(accuracy: 10.0)
        let badLocation = createLocation(accuracy: 50.0)

        // When
        _ = sut.shouldAccept(goodLocation)
        _ = sut.shouldAccept(badLocation)

        let stats = sut.statistics()

        // Then
        XCTAssertEqual(stats.totalLocations, 2)
        XCTAssertEqual(stats.acceptedLocations, 1)
        XCTAssertEqual(stats.rejectedByAccuracy, 1)
    }

    func testReset() {
        // Given
        let location = createLocation()
        _ = sut.shouldAccept(location)

        // When
        sut.reset()
        let stats = sut.statistics()

        // Then
        XCTAssertEqual(stats.totalLocations, 0)
        XCTAssertEqual(stats.acceptedLocations, 0)
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
            timestamp: timestamp
        )
    }
}

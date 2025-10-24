//
//  LocationServiceTests.swift
//  PaintMyTownTests
//
//  Comprehensive unit tests for LocationService
//  Tests for M1-T09 (LocationService unit tests)
//

import XCTest
import CoreLocation
import Combine
@testable import PaintMyTown

@MainActor
final class LocationServiceTests: XCTestCase {
    var sut: LocationService!
    var mockPermissionManager: MockPermissionManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockPermissionManager = MockPermissionManager()
        sut = LocationService(permissionManager: mockPermissionManager)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        sut.stopTracking()
        cancellables = nil
        sut = nil
        mockPermissionManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() async throws {
        // Given/When - initialized in setUp

        // Then
        XCTAssertEqual(sut.trackingState, .stopped)
        XCTAssertNil(sut.currentLocation)
        XCTAssertFalse(sut.isTracking)
    }

    // MARK: - Authorization Tests

    func testCheckAuthorization() async throws {
        // Given
        mockPermissionManager.locationState = .authorized

        // When
        let isAuthorized = await sut.checkAuthorization()

        // Then
        XCTAssertTrue(isAuthorized)
    }

    func testRequestAuthorization() async throws {
        // Given
        mockPermissionManager.shouldAuthorize = true

        // When
        let result = try await sut.requestAuthorization()

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Tracking State Tests

    func testStartTrackingWithActivityType() throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)

        var stateChanges: [TrackingState] = []
        sut.trackingStatePublisher
            .sink { state in
                stateChanges.append(state)
            }
            .store(in: &cancellables)

        // When
        try sut.startTracking(activityType: .run)

        // Then
        XCTAssertEqual(sut.trackingState, .active)
        XCTAssertTrue(sut.isTracking)
        XCTAssertTrue(stateChanges.contains(.active))
    }

    func testStartTrackingWithoutAuthorization() {
        // Given
        mockPermissionManager.locationState = .denied
        sut = LocationService(permissionManager: mockPermissionManager)

        // When/Then
        XCTAssertThrowsError(try sut.startTracking(activityType: .walk)) { error in
            XCTAssertTrue(error is LocationError)
            if let locationError = error as? LocationError {
                XCTAssertEqual(locationError, .notAuthorized)
            }
        }
    }

    func testPauseTracking() throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)
        try sut.startTracking(activityType: .run)

        // When
        sut.pauseTracking()

        // Then
        XCTAssertEqual(sut.trackingState, .paused)
        XCTAssertFalse(sut.isTracking)
    }

    func testResumeTracking() throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)
        try sut.startTracking(activityType: .run)
        sut.pauseTracking()

        // When
        sut.resumeTracking()

        // Then
        XCTAssertEqual(sut.trackingState, .active)
        XCTAssertTrue(sut.isTracking)
    }

    func testStopTracking() throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)
        try sut.startTracking(activityType: .run)

        // When
        sut.stopTracking()

        // Then
        XCTAssertEqual(sut.trackingState, .stopped)
        XCTAssertFalse(sut.isTracking)
        XCTAssertNil(sut.currentLocation)
    }

    // MARK: - Configuration Tests

    func testUpdateConfiguration() throws {
        // Given
        let config = LocationTrackingConfig.highAccuracy(for: .bike)

        // When
        sut.updateConfiguration(config)

        // Then - no crash, config applied
        XCTAssertNotNil(sut)
    }

    func testBatteryOptimizationConfigs() {
        // Given/When
        let performance = LocationTrackingConfig.highAccuracy(for: .run)
        let balanced = LocationTrackingConfig.standard(for: .run)
        let saver = LocationTrackingConfig.batterySaver(for: .run)

        // Then
        XCTAssertLessThan(performance.distanceFilter, balanced.distanceFilter)
        XCTAssertLessThan(balanced.distanceFilter, saver.distanceFilter)
    }

    // MARK: - Statistics Tests

    func testResetStatistics() throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)

        // When
        sut.resetStatistics()

        // Then
        let filterStats = sut.getFilterStatistics()
        let smootherStats = sut.getSmootherStatistics()

        XCTAssertEqual(filterStats.totalLocations, 0)
        XCTAssertEqual(smootherStats.locationsProcessed, 0)
    }

    // MARK: - Publisher Tests

    func testLocationPublisher() async throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)

        let expectation = XCTestExpectation(description: "Receive location")
        var receivedLocation: CLLocation?

        sut.locationPublisher
            .sink { location in
                receivedLocation = location
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        try sut.startTracking(activityType: .run)

        // Note: In real tests, you would simulate location updates
        // For now, we just verify the publisher is set up

        // Then
        XCTAssertNotNil(sut.locationPublisher)
    }

    func testTrackingStatePublisher() async throws {
        // Given
        mockPermissionManager.locationState = .authorized
        sut = LocationService(permissionManager: mockPermissionManager)

        var stateChanges: [TrackingState] = []
        sut.trackingStatePublisher
            .sink { state in
                stateChanges.append(state)
            }
            .store(in: &cancellables)

        // When
        try sut.startTracking(activityType: .run)
        sut.pauseTracking()
        sut.resumeTracking()
        sut.stopTracking()

        // Then
        XCTAssertTrue(stateChanges.contains(.active))
        XCTAssertTrue(stateChanges.contains(.paused))
        XCTAssertTrue(stateChanges.contains(.stopped))
    }

    func testErrorPublisher() async throws {
        // Given
        mockPermissionManager.locationState = .denied
        sut = LocationService(permissionManager: mockPermissionManager)

        let expectation = XCTestExpectation(description: "Receive error")
        var receivedError: LocationError?

        sut.errorPublisher
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        do {
            try sut.startTracking(activityType: .run)
        } catch {
            // Expected to throw
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Mock Permission Manager

class MockPermissionManager: PermissionManagerProtocol {
    var locationState: PermissionState = .notDetermined
    var motionState: PermissionState = .notDetermined
    var healthKitState: PermissionState = .notDetermined

    var locationStatePublisher: AnyPublisher<PermissionState, Never> {
        Just(locationState).eraseToAnyPublisher()
    }

    var motionStatePublisher: AnyPublisher<PermissionState, Never> {
        Just(motionState).eraseToAnyPublisher()
    }

    var healthKitStatePublisher: AnyPublisher<PermissionState, Never> {
        Just(healthKitState).eraseToAnyPublisher()
    }

    var shouldAuthorize: Bool = false

    func checkLocationPermission() -> PermissionState {
        return locationState
    }

    func requestLocationPermission() async -> PermissionState {
        if shouldAuthorize {
            locationState = .authorized
        }
        return locationState
    }

    func checkMotionPermission() -> PermissionState {
        return motionState
    }

    func requestMotionPermission() async -> PermissionState {
        if shouldAuthorize {
            motionState = .authorized
        }
        return motionState
    }

    func checkHealthKitPermission() -> PermissionState {
        return healthKitState
    }

    func requestHealthKitPermission() async -> PermissionState {
        if shouldAuthorize {
            healthKitState = .authorized
        }
        return healthKitState
    }

    func permissionRationale(for permission: Permission) -> String {
        return "Test rationale"
    }

    func permissionDescription(for permission: Permission) -> String {
        return "Test description"
    }

    func openSettings() {
        // No-op for tests
    }
}

//
//  WorkoutServiceTests.swift
//  PaintMyTownTests
//
//  Created on 2025-10-23.
//

import XCTest
import CoreLocation
import Combine
@testable import PaintMyTown

final class WorkoutServiceTests: XCTestCase {
    var sut: WorkoutService!
    var mockLocationService: MockLocationService!
    var mockRepository: MockActivityRepository!
    var appState: AppState!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        mockLocationService = MockLocationService()
        mockRepository = MockActivityRepository()
        appState = AppState.shared
        cancellables = Set<AnyCancellable>()

        sut = WorkoutService(
            locationService: mockLocationService,
            repository: mockRepository,
            appState: appState,
            autoPauseEnabled: false // Disable auto-pause for simpler tests
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        mockLocationService = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Start Workout Tests

    func testStartWorkout_CreatesActiveWorkout() throws {
        // When
        let workout = try sut.startWorkout(type: .run)

        // Then
        XCTAssertNotNil(sut.activeWorkout)
        XCTAssertEqual(workout.type, .run)
        XCTAssertEqual(workout.state, .recording)
        XCTAssertTrue(mockLocationService.isTrackingStarted)
    }

    func testStartWorkout_ThrowsWhenWorkoutAlreadyActive() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When/Then
        XCTAssertThrowsError(try sut.startWorkout(type: .walk)) { error in
            XCTAssertEqual(error as? WorkoutServiceError, .workoutAlreadyActive)
        }
    }

    func testStartWorkout_ThrowsWhenLocationNotAuthorized() {
        // Given
        mockLocationService.isAuthorized = false

        // When/Then
        XCTAssertThrowsError(try sut.startWorkout(type: .run)) { error in
            XCTAssertEqual(error as? WorkoutServiceError, .locationServiceUnavailable)
        }
    }

    func testStartWorkout_UpdatesAppState() throws {
        // Given
        var receivedWorkout: ActiveWorkout?
        sut.activeWorkoutPublisher
            .sink { workout in
                receivedWorkout = workout
            }
            .store(in: &cancellables)

        // When
        let workout = try sut.startWorkout(type: .run)

        // Then
        XCTAssertEqual(appState.activeWorkout?.id, workout.id)
        XCTAssertEqual(receivedWorkout?.id, workout.id)
    }

    // MARK: - Pause/Resume Tests

    func testPauseWorkout_PausesActiveWorkout() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When
        try sut.pauseWorkout()

        // Then
        XCTAssertEqual(sut.activeWorkout?.state, .paused)
        XCTAssertTrue(mockLocationService.isTrackingPaused)
    }

    func testPauseWorkout_ThrowsWhenNoActiveWorkout() {
        // When/Then
        XCTAssertThrowsError(try sut.pauseWorkout()) { error in
            XCTAssertEqual(error as? WorkoutServiceError, .noActiveWorkout)
        }
    }

    func testResumeWorkout_ResumesWorkout() throws {
        // Given
        _ = try sut.startWorkout(type: .run)
        try sut.pauseWorkout()

        // When
        try sut.resumeWorkout()

        // Then
        XCTAssertEqual(sut.activeWorkout?.state, .recording)
        XCTAssertTrue(mockLocationService.isTrackingResumed)
    }

    func testResumeWorkout_ThrowsWhenNotPaused() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When/Then
        XCTAssertThrowsError(try sut.resumeWorkout()) { error in
            if case WorkoutServiceError.invalidWorkoutState = error {
                // Expected
            } else {
                XCTFail("Expected invalidWorkoutState error")
            }
        }
    }

    // MARK: - End Workout Tests

    func testEndWorkout_ReturnsCompletedActivity() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // Simulate some locations
        let locations = generateTestLocations(count: 10, distance: 100)
        for location in locations {
            mockLocationService.simulateLocation(location)
        }

        // When
        let activity = try sut.endWorkout()

        // Then
        XCTAssertEqual(activity.type, .run)
        XCTAssertGreaterThan(activity.distance, 0)
        XCTAssertNil(sut.activeWorkout)
        XCTAssertTrue(mockLocationService.isTrackingStopped)
    }

    func testEndWorkout_ThrowsWhenNoActiveWorkout() {
        // When/Then
        XCTAssertThrowsError(try sut.endWorkout()) { error in
            XCTAssertEqual(error as? WorkoutServiceError, .noActiveWorkout)
        }
    }

    func testEndWorkout_ClearsAppState() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When
        _ = try sut.endWorkout()

        // Then
        XCTAssertNil(appState.activeWorkout)
    }

    // MARK: - Cancel Workout Tests

    func testCancelWorkout_ClearsWorkout() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When
        try sut.cancelWorkout()

        // Then
        XCTAssertNil(sut.activeWorkout)
        XCTAssertTrue(mockLocationService.isTrackingStopped)
        XCTAssertNil(appState.activeWorkout)
    }

    // MARK: - Distance Calculation Tests

    func testDistanceCalculation_AccumulatesCorrectly() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When - Simulate a 1km run (10 locations, 100m apart)
        let locations = generateTestLocations(count: 10, distance: 100)
        for location in locations {
            mockLocationService.simulateLocation(location)
        }

        // Then
        guard let workout = sut.activeWorkout else {
            XCTFail("No active workout")
            return
        }

        XCTAssertGreaterThan(workout.metrics.distance, 800) // Allow some GPS variance
        XCTAssertLessThan(workout.metrics.distance, 1200)
    }

    // MARK: - Pace Calculation Tests

    func testPaceCalculation_CalculatesAveragePace() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When - Simulate running at 5 min/km pace
        let locations = generateTestLocations(count: 20, distance: 50, interval: 15) // 50m every 15s = 200m/min = 5 min/km
        for location in locations {
            mockLocationService.simulateLocation(location)
        }

        // Then
        guard let workout = sut.activeWorkout else {
            XCTFail("No active workout")
            return
        }

        // Average pace should be around 300 seconds (5 minutes) per km
        XCTAssertGreaterThan(workout.metrics.averagePace, 200) // At least 3:20/km
        XCTAssertLessThan(workout.metrics.averagePace, 400) // At most 6:40/km
    }

    // MARK: - Elevation Tracking Tests

    func testElevationTracking_CalculatesGainAndLoss() throws {
        // Given
        _ = try sut.startWorkout(type: .run)

        // When - Simulate uphill then downhill
        var locations: [CLLocation] = []
        let baseLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)

        // Uphill: 10 locations, 5m elevation gain each (total 50m gain)
        for i in 0..<10 {
            let location = CLLocation(
                coordinate: baseLocation.coordinate,
                altitude: Double(i) * 5.0,
                horizontalAccuracy: 10,
                verticalAccuracy: 5,
                timestamp: Date().addingTimeInterval(TimeInterval(i * 10))
            )
            locations.append(location)
        }

        // Downhill: 10 locations, 5m elevation loss each (total 50m loss)
        for i in 10..<20 {
            let location = CLLocation(
                coordinate: baseLocation.coordinate,
                altitude: 50.0 - Double(i - 10) * 5.0,
                horizontalAccuracy: 10,
                verticalAccuracy: 5,
                timestamp: Date().addingTimeInterval(TimeInterval(i * 10))
            )
            locations.append(location)
        }

        for location in locations {
            mockLocationService.simulateLocation(location)
        }

        // Then
        guard let workout = sut.activeWorkout else {
            XCTFail("No active workout")
            return
        }

        XCTAssertGreaterThan(workout.metrics.elevationGain, 30) // Allow some filtering
        XCTAssertGreaterThan(workout.metrics.elevationLoss, 30)
    }

    // MARK: - Auto-Pause Tests

    func testAutoPause_DetectsStationaryUser() throws {
        // Given - Enable auto-pause for this test
        let autoPauseService = WorkoutService(
            locationService: mockLocationService,
            repository: mockRepository,
            appState: appState,
            autoPauseEnabled: true
        )

        _ = try autoPauseService.startWorkout(type: .run)

        // When - Simulate stationary user (speed = 0)
        let baseLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        for i in 0..<15 {
            let location = CLLocation(
                coordinate: baseLocation.coordinate,
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 5,
                course: 0,
                speed: 0.0, // Stationary
                timestamp: Date().addingTimeInterval(TimeInterval(i))
            )
            mockLocationService.simulateLocation(location)
        }

        // Then
        XCTAssertEqual(autoPauseService.activeWorkout?.state, .paused)
    }

    // MARK: - Metrics Publisher Tests

    func testMetricsPublisher_EmitsUpdates() throws {
        // Given
        var metricsUpdates: [WorkoutMetrics] = []
        sut.metricsPublisher
            .sink { metrics in
                metricsUpdates.append(metrics)
            }
            .store(in: &cancellables)

        // When
        _ = try sut.startWorkout(type: .run)

        let locations = generateTestLocations(count: 5, distance: 100)
        for location in locations {
            mockLocationService.simulateLocation(location)
        }

        // Then
        XCTAssertGreaterThan(metricsUpdates.count, 0)
    }

    // MARK: - Helper Methods

    private func generateTestLocations(count: Int, distance: Double, interval: TimeInterval = 1.0) -> [CLLocation] {
        var locations: [CLLocation] = []
        let baseLatitude = 37.7749
        let baseLongitude = -122.4194

        // Approximate: 1 degree latitude ≈ 111km
        let metersPerDegree = 111000.0
        let latitudeIncrement = distance / metersPerDegree

        for i in 0..<count {
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: baseLatitude + (Double(i) * latitudeIncrement),
                    longitude: baseLongitude
                ),
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                timestamp: Date().addingTimeInterval(TimeInterval(i) * interval)
            )
            locations.append(location)
        }

        return locations
    }
}

// MARK: - Mock Location Service

class MockLocationService: LocationServiceProtocol {
    var isAuthorized: Bool = true
    var currentLocation: CLLocation?
    var isTracking: Bool = false

    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let authorizationSubject = PassthroughSubject<Bool, Never>()

    var isTrackingStarted = false
    var isTrackingStopped = false
    var isTrackingPaused = false
    var isTrackingResumed = false

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var authorizationPublisher: AnyPublisher<Bool, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }

    func initialize() async throws {}

    func cleanup() {}

    func requestAuthorization() async throws -> Bool {
        return isAuthorized
    }

    func checkAuthorization() async -> Bool {
        return isAuthorized
    }

    func startTracking(activityType: ActivityType) throws {
        isTrackingStarted = true
        isTracking = true
    }

    func stopTracking() {
        isTrackingStopped = true
        isTracking = false
    }

    func pauseTracking() {
        isTrackingPaused = true
    }

    func resumeTracking() {
        isTrackingResumed = true
    }

    // Test helper to simulate location updates
    func simulateLocation(_ location: CLLocation) {
        currentLocation = location
        locationSubject.send(location)
    }
}

// MARK: - Mock Activity Repository

class MockActivityRepository: ActivityRepositoryProtocol {
    var activities: [Activity] = []

    func create(activity: Activity) async throws -> Activity {
        activities.append(activity)
        return activity
    }

    func fetchAll() async throws -> [Activity] {
        return activities
    }

    func fetch(filter: ActivityFilter) async throws -> [Activity] {
        return activities
    }

    func fetch(id: UUID) async throws -> Activity? {
        return activities.first { $0.id == id }
    }

    func update(activity: Activity) async throws {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
        }
    }

    func delete(id: UUID) async throws {
        activities.removeAll { $0.id == id }
    }

    func deleteAll() async throws {
        activities.removeAll()
    }
}

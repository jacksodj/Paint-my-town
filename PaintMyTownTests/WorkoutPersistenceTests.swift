//
//  WorkoutPersistenceTests.swift
//  PaintMyTownTests
//
//  Created on 2025-10-23.
//

import XCTest
import CoreData
@testable import PaintMyTown

final class WorkoutPersistenceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var activityRepository: ActivityRepository!
    var recoveryService: RecoveryService!
    var persistenceService: WorkoutPersistenceService!

    override func setUp() {
        super.setUp()

        // Use in-memory store for testing
        coreDataStack = CoreDataStack.inMemory()
        activityRepository = ActivityRepository(coreDataStack: coreDataStack)
        recoveryService = RecoveryService()
        persistenceService = WorkoutPersistenceService(
            coreDataStack: coreDataStack,
            activityRepository: activityRepository,
            recoveryService: recoveryService
        )
    }

    override func tearDown() {
        // Clean up recovery files
        Task {
            await recoveryService.clearWorkoutState()
        }

        coreDataStack = nil
        activityRepository = nil
        recoveryService = nil
        persistenceService = nil

        super.tearDown()
    }

    // MARK: - ActiveWorkout Tests

    func testActiveWorkoutCreation() {
        let workout = ActiveWorkout(type: .running)

        XCTAssertEqual(workout.type, .running)
        XCTAssertEqual(workout.distance, 0.0)
        XCTAssertEqual(workout.duration, 0.0)
        XCTAssertFalse(workout.isPaused)
        XCTAssertTrue(workout.locations.isEmpty)
    }

    func testActiveWorkoutAddLocation() {
        let workout = ActiveWorkout(type: .running)

        let location1 = LocationSample(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date(),
            speed: 2.0
        )

        workout.addLocation(location1)

        XCTAssertEqual(workout.locations.count, 1)
        XCTAssertEqual(workout.samplesRecorded, 1)
    }

    func testActiveWorkoutDistanceCalculation() {
        let workout = ActiveWorkout(type: .running)

        // Add two locations ~111km apart (1 degree latitude at equator)
        let location1 = LocationSample(
            latitude: 0.0,
            longitude: 0.0,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date(),
            speed: 2.0
        )

        let location2 = LocationSample(
            latitude: 1.0,
            longitude: 0.0,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date().addingTimeInterval(60),
            speed: 2.0
        )

        workout.addLocation(location1)
        workout.addLocation(location2)

        // Distance should be approximately 111km (111,000 meters)
        XCTAssertGreaterThan(workout.distance, 100_000)
        XCTAssertLessThan(workout.distance, 120_000)
    }

    func testActiveWorkoutPauseResume() {
        let workout = ActiveWorkout(type: .running)

        XCTAssertFalse(workout.isPaused)

        workout.pause()
        XCTAssertTrue(workout.isPaused)
        XCTAssertNotNil(workout.pauseStartTime)

        Thread.sleep(forTimeInterval: 0.1)

        workout.resume()
        XCTAssertFalse(workout.isPaused)
        XCTAssertNil(workout.pauseStartTime)
        XCTAssertGreaterThan(workout.totalPauseDuration, 0)
    }

    func testActiveWorkoutSufficientData() {
        let workout = ActiveWorkout(type: .running)

        // Initially should not have sufficient data
        XCTAssertFalse(workout.hasSufficientData)

        // Add two locations with meaningful distance
        let location1 = LocationSample(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date(),
            speed: 2.0
        )

        let location2 = LocationSample(
            latitude: 40.7138,
            longitude: -74.0060,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date().addingTimeInterval(10),
            speed: 2.0
        )

        workout.addLocation(location1)
        workout.addLocation(location2)

        // Should now have sufficient data (>10m, >2 locations)
        XCTAssertTrue(workout.hasSufficientData)
    }

    // MARK: - Persistence Tests

    func testSaveSmallWorkout() async throws {
        let workout = createTestWorkout(locationCount: 100)

        let savedActivity = try await persistenceService.saveWorkout(workout)

        XCTAssertEqual(savedActivity.id, workout.id)
        XCTAssertEqual(savedActivity.type, workout.type)
        XCTAssertEqual(savedActivity.locations.count, 100)
    }

    func testSaveLargeWorkout() async throws {
        let workout = createTestWorkout(locationCount: 2000)

        var progressUpdates: [SaveProgress] = []

        let savedActivity = try await persistenceService.saveWorkout(workout) { progress in
            progressUpdates.append(progress)
        }

        XCTAssertEqual(savedActivity.locations.count, 2000)
        XCTAssertFalse(progressUpdates.isEmpty)
    }

    func testSaveVeryLargeWorkout() async throws {
        let workout = createTestWorkout(locationCount: 5000)

        let savedActivity = try await persistenceService.saveWorkout(workout)

        XCTAssertEqual(savedActivity.locations.count, 5000)

        // Verify data was actually saved
        let fetchedActivity = try await activityRepository.fetch(id: savedActivity.id)
        XCTAssertNotNil(fetchedActivity)
        XCTAssertEqual(fetchedActivity?.locations.count, 5000)
    }

    func testSaveInsufficientData() async throws {
        let workout = ActiveWorkout(type: .running)

        // Only add 1 location with minimal distance
        let location = LocationSample(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date(),
            speed: 0.0
        )
        workout.addLocation(location)
        workout.end()

        do {
            _ = try await persistenceService.saveWorkout(workout)
            XCTFail("Should throw insufficient data error")
        } catch let error as WorkoutPersistenceError {
            if case .insufficientData = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testSaveWorkoutWithSplits() async throws {
        let workout = createTestWorkout(locationCount: 2000)

        // Manually add a split
        let split = Split(
            distance: 1000.0,
            duration: 300.0,
            pace: 300.0,
            elevationGain: 10.0
        )
        workout.splits.append(split)

        let savedActivity = try await persistenceService.saveWorkout(workout)

        XCTAssertEqual(savedActivity.splits.count, 1)
        XCTAssertEqual(savedActivity.splits.first?.distance, 1000.0)
    }

    // MARK: - Recovery Tests

    func testSaveAndLoadRecoveryData() async throws {
        let workout = createTestWorkout(locationCount: 100)

        // Save recovery data
        try await recoveryService.saveWorkoutState(workout)

        // Check if recovery data exists
        XCTAssertTrue(recoveryService.hasRecoveryData())

        // Load recovery data
        let recoveredWorkout = try await recoveryService.loadWorkoutState()

        XCTAssertNotNil(recoveredWorkout)
        XCTAssertEqual(recoveredWorkout?.id, workout.id)
        XCTAssertEqual(recoveredWorkout?.locations.count, 100)
    }

    func testClearRecoveryData() async throws {
        let workout = createTestWorkout(locationCount: 50)

        // Save recovery data
        try await recoveryService.saveWorkoutState(workout)
        XCTAssertTrue(recoveryService.hasRecoveryData())

        // Clear recovery data
        await recoveryService.clearWorkoutState()
        XCTAssertFalse(recoveryService.hasRecoveryData())
    }

    func testRecoveryInfo() async throws {
        let workout = createTestWorkout(locationCount: 100)

        // Save recovery data
        try await recoveryService.saveWorkoutState(workout)

        // Get recovery info
        let info = await recoveryService.getRecoveryInfo()

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.workoutID, workout.id)
        XCTAssertEqual(info?.activityType, workout.type)
        XCTAssertEqual(info?.locationCount, 100)
    }

    func testRecoveryDataValidation() async throws {
        let workout = createTestWorkout(locationCount: 100)

        // Create an old workout (8 days ago)
        let oldWorkout = ActiveWorkout(
            type: .running,
            startDate: Date().addingTimeInterval(-8 * 24 * 60 * 60)
        )
        oldWorkout.addLocation(LocationSample(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date().addingTimeInterval(-8 * 24 * 60 * 60),
            speed: 2.0
        ))

        try await recoveryService.saveWorkoutState(oldWorkout)

        // Should throw corrupted data error for old workout
        do {
            _ = try await recoveryService.loadWorkoutState()
            XCTFail("Should throw corrupted data error for old workout")
        } catch let error as WorkoutPersistenceError {
            if case .recoveryDataCorrupted = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        }
    }

    func testBackupToFileSystem() async throws {
        let workout = createTestWorkout(locationCount: 100)
        let activity = workout.toActivity()

        // Save to file system backup
        try await recoveryService.saveToFileSystemBackup(activity)

        // List backups
        let backups = recoveryService.listBackupFiles()

        XCTAssertFalse(backups.isEmpty)

        // Load from backup
        if let backupFile = backups.first {
            let loadedActivity = try await recoveryService.loadFromBackup(url: backupFile)
            XCTAssertEqual(loadedActivity.id, activity.id)
        }
    }

    // MARK: - Batch Insert Tests

    func testBatchInsertPerformance() async throws {
        let workout = createTestWorkout(locationCount: 5000)

        let startTime = Date()

        _ = try await persistenceService.saveWorkout(workout)

        let duration = Date().timeIntervalSince(startTime)

        // Should complete in reasonable time (< 10 seconds for 5000 locations)
        XCTAssertLessThan(duration, 10.0)

        print("Saved 5000 locations in \(String(format: "%.2f", duration)) seconds")
    }

    func testConcurrentSaves() async throws {
        // Create multiple workouts
        let workout1 = createTestWorkout(locationCount: 100)
        let workout2 = createTestWorkout(locationCount: 100)
        let workout3 = createTestWorkout(locationCount: 100)

        // Save concurrently
        async let save1 = persistenceService.saveWorkout(workout1)
        async let save2 = persistenceService.saveWorkout(workout2)
        async let save3 = persistenceService.saveWorkout(workout3)

        let results = try await [save1, save2, save3]

        XCTAssertEqual(results.count, 3)

        // Verify all were saved
        let allActivities = try await activityRepository.fetchAll()
        XCTAssertEqual(allActivities.count, 3)
    }

    // MARK: - Error Handling Tests

    func testWorkoutPersistenceErrorSeverity() {
        let insufficientError = WorkoutPersistenceError.insufficientData(reason: "test")
        XCTAssertEqual(insufficientError.severity, .warning)

        let saveError = WorkoutPersistenceError.saveFailed(
            underlying: NSError(domain: "test", code: -1)
        )
        XCTAssertEqual(saveError.severity, .error)

        let partialError = WorkoutPersistenceError.partialSaveFailure(
            savedItems: 100,
            totalItems: 200,
            underlying: NSError(domain: "test", code: -1)
        )
        XCTAssertEqual(partialError.severity, .critical)
    }

    func testWorkoutPersistenceErrorRetry() {
        let insufficientError = WorkoutPersistenceError.insufficientData(reason: "test")
        XCTAssertFalse(insufficientError.shouldRetry)

        let timeoutError = WorkoutPersistenceError.saveTimeout
        XCTAssertTrue(timeoutError.shouldRetry)

        let concurrentError = WorkoutPersistenceError.concurrentModification
        XCTAssertTrue(concurrentError.shouldRetry)
    }

    // MARK: - Helper Methods

    private func createTestWorkout(locationCount: Int) -> ActiveWorkout {
        let workout = ActiveWorkout(type: .running)

        // Generate locations in a small area
        let baseLatitude = 40.7128
        let baseLongitude = -74.0060
        let startTime = Date()

        for i in 0..<locationCount {
            let latitude = baseLatitude + Double(i) * 0.0001
            let longitude = baseLongitude + Double(i) * 0.0001
            let timestamp = startTime.addingTimeInterval(Double(i))

            let location = LocationSample(
                latitude: latitude,
                longitude: longitude,
                altitude: 10.0 + Double(i) * 0.1,
                horizontalAccuracy: 5.0,
                verticalAccuracy: 5.0,
                timestamp: timestamp,
                speed: 2.0
            )

            workout.addLocation(location)
        }

        workout.end()

        return workout
    }
}

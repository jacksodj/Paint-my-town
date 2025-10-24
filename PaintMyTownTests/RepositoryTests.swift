//
//  RepositoryTests.swift
//  PaintMyTownTests
//
//  Created on 2025-10-23.
//

import XCTest
import CoreData
@testable import PaintMyTown

final class RepositoryTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var activityRepository: ActivityRepository!
    var coverageTileRepository: CoverageTileRepository!

    override func setUpWithError() throws {
        super.setUp()
        // Use in-memory store for testing
        coreDataStack = CoreDataStack.inMemory()
        activityRepository = ActivityRepository(coreDataStack: coreDataStack)
        coverageTileRepository = CoverageTileRepository(coreDataStack: coreDataStack)
    }

    override func tearDownWithError() throws {
        coreDataStack = nil
        activityRepository = nil
        coverageTileRepository = nil
        super.tearDown()
    }

    // MARK: - Activity Repository Tests

    func testCreateActivity() async throws {
        // Given
        let activity = createTestActivity()

        // When
        let createdActivity = try await activityRepository.create(activity: activity)

        // Then
        XCTAssertEqual(createdActivity.id, activity.id)
        XCTAssertEqual(createdActivity.type, activity.type)
        XCTAssertEqual(createdActivity.distance, activity.distance, accuracy: 0.01)
        XCTAssertEqual(createdActivity.duration, activity.duration, accuracy: 0.01)
    }

    func testFetchAllActivities() async throws {
        // Given
        let activity1 = createTestActivity(type: .run, distance: 5000)
        let activity2 = createTestActivity(type: .walk, distance: 3000)

        _ = try await activityRepository.create(activity: activity1)
        _ = try await activityRepository.create(activity: activity2)

        // When
        let activities = try await activityRepository.fetchAll()

        // Then
        XCTAssertEqual(activities.count, 2)
        // Should be sorted by start date descending
        XCTAssertTrue(activities[0].startDate >= activities[1].startDate)
    }

    func testFetchActivityById() async throws {
        // Given
        let activity = createTestActivity()
        _ = try await activityRepository.create(activity: activity)

        // When
        let fetchedActivity = try await activityRepository.fetch(id: activity.id)

        // Then
        XCTAssertNotNil(fetchedActivity)
        XCTAssertEqual(fetchedActivity?.id, activity.id)
        XCTAssertEqual(fetchedActivity?.type, activity.type)
    }

    func testFetchActivityByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()

        // When
        let fetchedActivity = try await activityRepository.fetch(id: nonExistentId)

        // Then
        XCTAssertNil(fetchedActivity)
    }

    func testFetchActivitiesWithDateRangeFilter() async throws {
        // Given
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let activity1 = createTestActivity(startDate: now)
        let activity2 = createTestActivity(startDate: yesterday)
        let activity3 = createTestActivity(startDate: lastWeek)

        _ = try await activityRepository.create(activity: activity1)
        _ = try await activityRepository.create(activity: activity2)
        _ = try await activityRepository.create(activity: activity3)

        // When
        let filter = ActivityFilter(dateRange: DateRange(start: yesterday, end: now))
        let filteredActivities = try await activityRepository.fetch(filter: filter)

        // Then
        XCTAssertEqual(filteredActivities.count, 2)
    }

    func testFetchActivitiesWithTypeFilter() async throws {
        // Given
        let runActivity = createTestActivity(type: .run)
        let walkActivity = createTestActivity(type: .walk)
        let bikeActivity = createTestActivity(type: .bike)

        _ = try await activityRepository.create(activity: runActivity)
        _ = try await activityRepository.create(activity: walkActivity)
        _ = try await activityRepository.create(activity: bikeActivity)

        // When
        let filter = ActivityFilter(activityTypes: [.run, .walk])
        let filteredActivities = try await activityRepository.fetch(filter: filter)

        // Then
        XCTAssertEqual(filteredActivities.count, 2)
        XCTAssertTrue(filteredActivities.allSatisfy { $0.type == .run || $0.type == .walk })
    }

    func testFetchActivitiesWithDistanceFilter() async throws {
        // Given
        let shortActivity = createTestActivity(distance: 1000) // 1km
        let mediumActivity = createTestActivity(distance: 5000) // 5km
        let longActivity = createTestActivity(distance: 10000) // 10km

        _ = try await activityRepository.create(activity: shortActivity)
        _ = try await activityRepository.create(activity: mediumActivity)
        _ = try await activityRepository.create(activity: longActivity)

        // When
        let filter = ActivityFilter(minDistance: 3000, maxDistance: 7000)
        let filteredActivities = try await activityRepository.fetch(filter: filter)

        // Then
        XCTAssertEqual(filteredActivities.count, 1)
        XCTAssertEqual(filteredActivities.first?.distance, 5000, accuracy: 0.01)
    }

    func testUpdateActivity() async throws {
        // Given
        let activity = createTestActivity(notes: "Original notes")
        _ = try await activityRepository.create(activity: activity)

        // When
        var updatedActivity = activity
        updatedActivity = Activity(
            id: activity.id,
            type: activity.type,
            startDate: activity.startDate,
            endDate: activity.endDate,
            distance: activity.distance,
            duration: activity.duration,
            elevationGain: activity.elevationGain,
            elevationLoss: activity.elevationLoss,
            averagePace: activity.averagePace,
            notes: "Updated notes",
            locations: activity.locations,
            splits: activity.splits
        )
        try await activityRepository.update(activity: updatedActivity)

        // Then
        let fetchedActivity = try await activityRepository.fetch(id: activity.id)
        XCTAssertEqual(fetchedActivity?.notes, "Updated notes")
    }

    func testDeleteActivity() async throws {
        // Given
        let activity = createTestActivity()
        _ = try await activityRepository.create(activity: activity)

        // When
        try await activityRepository.delete(id: activity.id)

        // Then
        let fetchedActivity = try await activityRepository.fetch(id: activity.id)
        XCTAssertNil(fetchedActivity)
    }

    func testDeleteAllActivities() async throws {
        // Given
        let activity1 = createTestActivity()
        let activity2 = createTestActivity()

        _ = try await activityRepository.create(activity: activity1)
        _ = try await activityRepository.create(activity: activity2)

        // When
        try await activityRepository.deleteAll()

        // Then
        let activities = try await activityRepository.fetchAll()
        XCTAssertTrue(activities.isEmpty)
    }

    func testActivityWithLocationsAndSplits() async throws {
        // Given
        let locations = [
            LocationSample(latitude: 37.7749, longitude: -122.4194, altitude: 10, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date(), speed: 2.5),
            LocationSample(latitude: 37.7750, longitude: -122.4195, altitude: 11, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date().addingTimeInterval(10), speed: 2.6)
        ]

        let splits = [
            Split(distance: 1000, duration: 300, pace: 300, elevationGain: 10)
        ]

        let activity = createTestActivity(locations: locations, splits: splits)

        // When
        _ = try await activityRepository.create(activity: activity)
        let fetchedActivity = try await activityRepository.fetch(id: activity.id)

        // Then
        XCTAssertNotNil(fetchedActivity)
        XCTAssertEqual(fetchedActivity?.locations.count, 2)
        XCTAssertEqual(fetchedActivity?.splits.count, 1)
        XCTAssertEqual(fetchedActivity?.locations.first?.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(fetchedActivity?.splits.first?.distance, 1000, accuracy: 0.01)
    }

    // MARK: - Coverage Tile Repository Tests

    func testUpsertNewTile() async throws {
        // Given
        let tile = createTestCoverageTile(geohash: "9q8yy")

        // When
        try await coverageTileRepository.upsertTiles([tile])

        // Then
        let fetchedTiles = try await coverageTileRepository.fetchTiles(matching: ["9q8yy"])
        XCTAssertEqual(fetchedTiles.count, 1)
        XCTAssertEqual(fetchedTiles.first?.geohash, "9q8yy")
        XCTAssertEqual(fetchedTiles.first?.visitCount, 1)
    }

    func testUpsertExistingTile() async throws {
        // Given
        let tile1 = createTestCoverageTile(geohash: "9q8yy", visitCount: 1)
        try await coverageTileRepository.upsertTiles([tile1])

        // When - Upsert again
        let tile2 = createTestCoverageTile(geohash: "9q8yy", visitCount: 1)
        try await coverageTileRepository.upsertTiles([tile2])

        // Then
        let fetchedTiles = try await coverageTileRepository.fetchTiles(matching: ["9q8yy"])
        XCTAssertEqual(fetchedTiles.count, 1)
        XCTAssertEqual(fetchedTiles.first?.visitCount, 2) // Should increment
    }

    func testFetchTilesByGeohash() async throws {
        // Given
        let tile1 = createTestCoverageTile(geohash: "9q8yy")
        let tile2 = createTestCoverageTile(geohash: "9q8yz")
        let tile3 = createTestCoverageTile(geohash: "9q8yu")

        try await coverageTileRepository.upsertTiles([tile1, tile2, tile3])

        // When
        let fetchedTiles = try await coverageTileRepository.fetchTiles(matching: ["9q8yy", "9q8yz"])

        // Then
        XCTAssertEqual(fetchedTiles.count, 2)
        let geohashes = fetchedTiles.map { $0.geohash }
        XCTAssertTrue(geohashes.contains("9q8yy"))
        XCTAssertTrue(geohashes.contains("9q8yz"))
        XCTAssertFalse(geohashes.contains("9q8yu"))
    }

    func testFetchTilesByRegion() async throws {
        // Given
        let sanFranciscoTile = createTestCoverageTile(geohash: "9q8yy", latitude: 37.7749, longitude: -122.4194)
        let oaklandTile = createTestCoverageTile(geohash: "9q9p1", latitude: 37.8044, longitude: -122.2712)

        try await coverageTileRepository.upsertTiles([sanFranciscoTile, oaklandTile])

        // When - Fetch only San Francisco area
        let sfRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        let fetchedTiles = try await coverageTileRepository.fetchTiles(in: sfRegion)

        // Then
        XCTAssertEqual(fetchedTiles.count, 1)
        XCTAssertEqual(fetchedTiles.first?.geohash, "9q8yy")
    }

    func testDeleteAllTiles() async throws {
        // Given
        let tile1 = createTestCoverageTile(geohash: "9q8yy")
        let tile2 = createTestCoverageTile(geohash: "9q8yz")

        try await coverageTileRepository.upsertTiles([tile1, tile2])

        // When
        try await coverageTileRepository.deleteAll()

        // Then
        let fetchedTiles = try await coverageTileRepository.fetchTiles(matching: ["9q8yy", "9q8yz"])
        XCTAssertTrue(fetchedTiles.isEmpty)
    }

    // MARK: - Helper Methods

    private func createTestActivity(
        type: ActivityType = .run,
        startDate: Date = Date(),
        distance: Double = 5000.0,
        locations: [LocationSample] = [],
        splits: [Split] = [],
        notes: String? = nil
    ) -> Activity {
        let endDate = startDate.addingTimeInterval(1800) // 30 minutes

        return Activity(
            id: UUID(),
            type: type,
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            duration: 1800,
            elevationGain: 50,
            elevationLoss: 45,
            averagePace: 360,
            notes: notes,
            locations: locations,
            splits: splits
        )
    }

    private func createTestCoverageTile(
        geohash: String,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        visitCount: Int = 1
    ) -> CoverageTile {
        CoverageTile(
            geohash: geohash,
            latitude: latitude,
            longitude: longitude,
            visitCount: visitCount,
            firstVisited: Date(),
            lastVisited: Date()
        )
    }
}

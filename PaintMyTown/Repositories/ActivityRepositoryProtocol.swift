//
//  ActivityRepositoryProtocol.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Protocol defining the contract for activity data persistence
protocol ActivityRepositoryProtocol {
    /// Create a new activity
    /// - Parameter activity: The activity to create
    /// - Returns: The created activity with persisted ID
    func create(activity: Activity) async throws -> Activity

    /// Fetch all activities
    /// - Returns: Array of all activities, sorted by start date (descending)
    func fetchAll() async throws -> [Activity]

    /// Fetch activities matching a filter
    /// - Parameter filter: The filter criteria to apply
    /// - Returns: Array of activities matching the filter
    func fetch(filter: ActivityFilter) async throws -> [Activity]

    /// Fetch a single activity by ID
    /// - Parameter id: The unique identifier of the activity
    /// - Returns: The activity if found, nil otherwise
    func fetch(id: UUID) async throws -> Activity?

    /// Update an existing activity
    /// - Parameter activity: The activity with updated values
    func update(activity: Activity) async throws

    /// Delete an activity by ID
    /// - Parameter id: The unique identifier of the activity to delete
    func delete(id: UUID) async throws

    /// Delete all activities
    func deleteAll() async throws
}

// MARK: - Activity Filter

/// Filter criteria for fetching activities
struct ActivityFilter {
    var dateRange: DateRange?
    var activityTypes: Set<ActivityType>?
    var minDistance: Double? // meters
    var maxDistance: Double? // meters
    var minDuration: Double? // seconds
    var maxDuration: Double? // seconds

    init(
        dateRange: DateRange? = nil,
        activityTypes: Set<ActivityType>? = nil,
        minDistance: Double? = nil,
        maxDistance: Double? = nil,
        minDuration: Double? = nil,
        maxDuration: Double? = nil
    ) {
        self.dateRange = dateRange
        self.activityTypes = activityTypes
        self.minDistance = minDistance
        self.maxDistance = maxDistance
        self.minDuration = minDuration
        self.maxDuration = maxDuration
    }

    static let `default` = ActivityFilter()
}

/// Date range for filtering
struct DateRange {
    let start: Date
    let end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    static var lastWeek: DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        return DateRange(start: start, end: end)
    }

    static var lastMonth: DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: end)!
        return DateRange(start: start, end: end)
    }

    static var thisYear: DateRange {
        let end = Date()
        let start = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: end), month: 1, day: 1))!
        return DateRange(start: start, end: end)
    }
}

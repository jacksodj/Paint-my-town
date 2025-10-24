//
//  HistoryViewModel.swift
//  PaintMyTown
//
//  Created on 2025-10-24.
//

import Foundation
import Combine

/// Sort options for activity list
enum ActivitySortOption: String, CaseIterable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case distanceLongest = "Distance (Longest)"
    case distanceShortest = "Distance (Shortest)"
    case durationLongest = "Duration (Longest)"
    case durationShortest = "Duration (Shortest)"
}

/// ViewModel for the History view handling activity list and search
@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All activities loaded from repository
    @Published var activities: [Activity] = []

    /// Filtered activities based on search and sort
    @Published var filteredActivities: [Activity] = []

    /// Search text for filtering activities
    @Published var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }

    /// Selected sort option
    @Published var sortOption: ActivitySortOption = .dateNewest {
        didSet {
            applyFilters()
        }
    }

    /// Filter by activity type (nil = all types)
    @Published var filterType: ActivityType? {
        didSet {
            applyFilters()
        }
    }

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message to display
    @Published var errorMessage: String?

    /// Selected activity for detail view
    @Published var selectedActivity: Activity?

    /// Show activity detail sheet
    @Published var showActivityDetail: Bool = false

    /// Show delete confirmation
    @Published var showDeleteConfirmation: Bool = false

    /// Activity to delete
    @Published var activityToDelete: Activity?

    // MARK: - Private Properties

    private let activityRepository: ActivityRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(activityRepository: ActivityRepositoryProtocol) {
        self.activityRepository = activityRepository
    }

    convenience init() {
        let container = DependencyContainer.shared
        let repository = container.resolve(ActivityRepositoryProtocol.self)
        self.init(activityRepository: repository)
    }

    // MARK: - Public Methods

    /// Load all activities from repository
    func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedActivities = try await activityRepository.fetchAll()
            activities = loadedActivities
            applyFilters()
            Logger.shared.info("Loaded \(loadedActivities.count) activities", category: .ui)
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            Logger.shared.error("Failed to load activities", error: error, category: .ui)
        }

        isLoading = false
    }

    /// Refresh activities (for pull-to-refresh)
    func refreshActivities() async {
        await loadActivities()
    }

    /// Select an activity to view details
    func selectActivity(_ activity: Activity) {
        selectedActivity = activity
        showActivityDetail = true
    }

    /// Request to delete an activity
    func requestDelete(_ activity: Activity) {
        activityToDelete = activity
        showDeleteConfirmation = true
    }

    /// Confirm and delete activity
    func confirmDelete() async {
        guard let activity = activityToDelete else { return }

        do {
            try await activityRepository.delete(id: activity.id)

            // Remove from local arrays
            activities.removeAll { $0.id == activity.id }
            filteredActivities.removeAll { $0.id == activity.id }

            Logger.shared.info("Deleted activity \(activity.id)", category: .ui)

            // Clear delete state
            activityToDelete = nil
            showDeleteConfirmation = false
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
            Logger.shared.error("Failed to delete activity", error: error, category: .ui)
        }
    }

    /// Cancel delete
    func cancelDelete() {
        activityToDelete = nil
        showDeleteConfirmation = false
    }

    // MARK: - Private Methods

    /// Apply search and sort filters
    private func applyFilters() {
        var result = activities

        // Apply type filter
        if let type = filterType {
            result = result.filter { $0.type == type }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { activity in
                // Search in activity type
                if activity.type.rawValue.localizedCaseInsensitiveContains(searchText) {
                    return true
                }

                // Search in notes
                if let notes = activity.notes,
                   notes.localizedCaseInsensitiveContains(searchText) {
                    return true
                }

                // Search in formatted distance
                let distanceText = activity.formattedDistance(unit: UserDefaultsManager.shared.distanceUnit)
                if distanceText.localizedCaseInsensitiveContains(searchText) {
                    return true
                }

                return false
            }
        }

        // Apply sort
        switch sortOption {
        case .dateNewest:
            result.sort { $0.startDate > $1.startDate }
        case .dateOldest:
            result.sort { $0.startDate < $1.startDate }
        case .distanceLongest:
            result.sort { $0.distance > $1.distance }
        case .distanceShortest:
            result.sort { $0.distance < $1.distance }
        case .durationLongest:
            result.sort { $0.duration > $1.duration }
        case .durationShortest:
            result.sort { $0.duration < $1.duration }
        }

        filteredActivities = result
    }

    // MARK: - Computed Properties

    /// Total number of activities
    var totalActivities: Int {
        activities.count
    }

    /// Total distance across all activities
    var totalDistance: Double {
        activities.reduce(0) { $0 + $1.distance }
    }

    /// Total duration across all activities
    var totalDuration: Double {
        activities.reduce(0) { $0 + $1.duration }
    }

    /// Formatted total distance
    var formattedTotalDistance: String {
        let unit = UserDefaultsManager.shared.distanceUnit
        let value = totalDistance / unit.metersPerUnit
        return String(format: "%.1f %@", value, unit.abbreviation)
    }

    /// Formatted total duration
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    /// Whether the list is empty
    var isEmpty: Bool {
        filteredActivities.isEmpty
    }
}

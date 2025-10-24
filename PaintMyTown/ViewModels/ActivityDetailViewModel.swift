//
//  ActivityDetailViewModel.swift
//  PaintMyTown
//
//  Created on 2025-10-24.
//

import Foundation
import CoreLocation
import Combine

/// ViewModel for the Activity Detail view
@MainActor
final class ActivityDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The activity being viewed
    @Published var activity: Activity

    /// Whether editing mode is active
    @Published var isEditing: Bool = false

    /// Edited notes
    @Published var editedNotes: String = ""

    /// Edited activity type
    @Published var editedType: ActivityType

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    /// Show export sheet
    @Published var showExportSheet: Bool = false

    // MARK: - Private Properties

    private let activityRepository: ActivityRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(activity: Activity, activityRepository: ActivityRepositoryProtocol) {
        self.activity = activity
        self.activityRepository = activityRepository
        self.editedType = activity.type
        self.editedNotes = activity.notes ?? ""
    }

    convenience init(activity: Activity) {
        let container = DependencyContainer.shared
        let repository = container.resolve(ActivityRepositoryProtocol.self)
        self.init(activity: activity, activityRepository: repository)
    }

    // MARK: - Public Methods

    /// Start editing the activity
    func startEditing() {
        isEditing = true
        editedType = activity.type
        editedNotes = activity.notes ?? ""
    }

    /// Cancel editing
    func cancelEditing() {
        isEditing = false
        editedType = activity.type
        editedNotes = activity.notes ?? ""
    }

    /// Save changes to activity
    func saveChanges() async {
        isLoading = true
        errorMessage = nil

        // Create updated activity
        let updatedActivity = Activity(
            id: activity.id,
            type: editedType,
            startDate: activity.startDate,
            endDate: activity.endDate,
            distance: activity.distance,
            duration: activity.duration,
            elevationGain: activity.elevationGain,
            elevationLoss: activity.elevationLoss,
            averagePace: activity.averagePace,
            notes: editedNotes.isEmpty ? nil : editedNotes,
            locations: activity.locations,
            splits: activity.splits
        )

        do {
            try await activityRepository.update(activity: updatedActivity)
            activity = updatedActivity
            isEditing = false

            Logger.shared.info("Updated activity \(activity.id)", category: .ui)

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            Logger.shared.error("Failed to update activity", error: error, category: .ui)

            // Error haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isLoading = false
    }

    /// Export activity as GPX (placeholder for M5)
    func exportActivity() {
        showExportSheet = true
        // GPX export will be implemented in M5
    }

    // MARK: - Computed Properties

    /// Route coordinates for map display
    var routeCoordinates: [CLLocationCoordinate2D] {
        activity.locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// Map region to display the route
    var mapRegion: (center: CLLocationCoordinate2D, span: Double)? {
        guard !activity.locations.isEmpty else { return nil }

        let latitudes = activity.locations.map { $0.latitude }
        let longitudes = activity.locations.map { $0.longitude }

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return nil
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = (maxLat - minLat) * 1.3 // Add 30% padding
        let lonDelta = (maxLon - minLon) * 1.3

        let span = max(latDelta, lonDelta, 0.01) // Minimum span

        return (CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon), span)
    }

    /// Formatted distance
    func formattedDistance(unit: DistanceUnit) -> String {
        activity.formattedDistance(unit: unit)
    }

    /// Formatted pace
    func formattedPace(unit: DistanceUnit) -> String {
        activity.formattedPace(unit: unit)
    }

    /// Formatted elevation gain
    var formattedElevationGain: String {
        String(format: "%.0f m", activity.elevationGain)
    }

    /// Formatted elevation loss
    var formattedElevationLoss: String {
        String(format: "%.0f m", activity.elevationLoss)
    }

    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: activity.startDate)
    }

    /// Has changes to save
    var hasChanges: Bool {
        editedType != activity.type || editedNotes != (activity.notes ?? "")
    }

    /// Split count
    var splitCount: Int {
        activity.splits.count
    }

    /// Location count
    var locationCount: Int {
        activity.locations.count
    }

    /// Pace data for chart (split paces)
    var paceData: [(distance: Double, pace: Double)] {
        activity.splits.enumerated().map { index, split in
            let cumulativeDistance = Double(index + 1) * (split.distance / 1000.0)
            return (cumulativeDistance, split.pace)
        }
    }

    /// Elevation data for chart
    var elevationData: [(distance: Double, elevation: Double)] {
        guard !activity.locations.isEmpty else { return [] }

        var result: [(Double, Double)] = []
        var cumulativeDistance: Double = 0
        var previousLocation: LocationSample?

        for location in activity.locations {
            if let prev = previousLocation {
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: prev.latitude, longitude: prev.longitude),
                    to: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                )
                cumulativeDistance += distance
            }

            result.append((cumulativeDistance / 1000.0, location.altitude))
            previousLocation = location
        }

        return result
    }

    // MARK: - Private Methods

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

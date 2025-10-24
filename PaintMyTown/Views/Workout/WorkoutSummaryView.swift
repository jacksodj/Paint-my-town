//
//  WorkoutSummaryView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI
import MapKit

/// Summary view displayed after completing a workout
struct WorkoutSummaryView: View {
    let activity: Activity
    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var showDiscardConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: activityIcon)
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)

                        Text("Workout Complete!")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(activity.type.displayName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Summary Stats
                    VStack(spacing: 16) {
                        // Distance and Duration
                        HStack(spacing: 16) {
                            SummaryStatCard(
                                title: "Distance",
                                value: formattedDistance,
                                icon: "arrow.left.and.right"
                            )

                            SummaryStatCard(
                                title: "Duration",
                                value: activity.formattedDuration,
                                icon: "clock"
                            )
                        }

                        // Pace and Elevation
                        HStack(spacing: 16) {
                            SummaryStatCard(
                                title: "Avg Pace",
                                value: formattedPace,
                                icon: "speedometer"
                            )

                            SummaryStatCard(
                                title: "Elevation",
                                value: formattedElevation,
                                icon: "arrow.up.right"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Route Map Preview
                    if !activity.locations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route")
                                .font(.headline)
                                .padding(.horizontal)

                            RoutePreviewMap(locations: activity.locations)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }

                    // Splits (if any)
                    if !activity.splits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Splits")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(Array(activity.splits.enumerated()), id: \.offset) { index, split in
                                SplitRowView(splitNumber: index + 1, split: split)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard", role: .destructive) {
                        showDiscardConfirmation = true
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Discard Workout?",
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Workout", role: .destructive) {
                    onDiscard()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This workout will be permanently deleted and cannot be recovered.")
            }
        }
    }

    // MARK: - Computed Properties

    private var activityIcon: String {
        switch activity.type {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .bike: return "bicycle"
        }
    }

    private var formattedDistance: String {
        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        return activity.formattedDistance(unit: distanceUnit)
    }

    private var formattedPace: String {
        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        return activity.formattedPace(unit: distanceUnit)
    }

    private var formattedElevation: String {
        String(format: "%.0f m", activity.elevationGain)
    }
}

// MARK: - Supporting Views

/// Summary stat card
struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

/// Split row view
struct SplitRowView: View {
    let splitNumber: Int
    let split: Split

    var body: some View {
        HStack {
            Text("Split \(splitNumber)")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedPace)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private var formattedPace: String {
        let minutes = Int(split.pace) / 60
        let seconds = Int(split.pace) % 60
        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        return String(format: "%d:%02d /%@", minutes, seconds, distanceUnit.abbreviation)
    }

    private var formattedDuration: String {
        let minutes = Int(split.duration) / 60
        let seconds = Int(split.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Route preview map
struct RoutePreviewMap: View {
    let locations: [LocationSample]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [RoutePoint]()) { point in
            MapPin(coordinate: point.coordinate)
        }
        .disabled(true)
        .onAppear {
            updateRegion()
        }
    }

    private func updateRegion() {
        guard !locations.isEmpty else { return }

        let coordinates = locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else {
            return
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.2
        let spanLon = (maxLon - minLon) * 1.2

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(spanLat, 0.01),
                longitudeDelta: max(spanLon, 0.01)
            )
        )
    }
}

// MARK: - Preview

#Preview {
    WorkoutSummaryView(
        activity: Activity(
            type: .run,
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            distance: 5240,
            duration: 1800,
            elevationGain: 142,
            elevationLoss: 138,
            averagePace: 343,
            splits: [
                Split(distance: 1000, duration: 343, pace: 343, elevationGain: 20),
                Split(distance: 1000, duration: 340, pace: 340, elevationGain: 25),
                Split(distance: 1000, duration: 345, pace: 345, elevationGain: 18)
            ]
        ),
        onSave: {
            print("Save")
        },
        onDiscard: {
            print("Discard")
        }
    )
}

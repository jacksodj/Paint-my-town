//
//  ActivityDetailView.swift
//  PaintMyTown
//
//  Created on 2025-10-24.
//

import SwiftUI
import MapKit
import Charts

/// Detailed view for a single activity
struct ActivityDetailView: View {
    @StateObject private var detailViewModel: ActivityDetailViewModel
    @ObservedObject var historyViewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let distanceUnit: DistanceUnit

    init(activity: Activity, viewModel: HistoryViewModel) {
        self._detailViewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
        self.historyViewModel = viewModel
        self.distanceUnit = UserDefaultsManager.shared.distanceUnit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Route Map
                    if let region = detailViewModel.mapRegion {
                        ActivityRouteMapView(
                            routeCoordinates: detailViewModel.routeCoordinates,
                            center: region.center,
                            span: region.span
                        )
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Key Metrics
                    metricsSection

                    // Splits
                    if !detailViewModel.activity.splits.isEmpty {
                        splitsSection
                    }

                    // Pace Chart
                    if !detailViewModel.paceData.isEmpty {
                        paceChartSection
                    }

                    // Elevation Chart
                    if !detailViewModel.elevationData.isEmpty {
                        elevationChartSection
                    }

                    // Notes Section
                    notesSection

                    // Info Section
                    infoSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(detailViewModel.activity.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if detailViewModel.isEditing {
                            Button("Save") {
                                Task {
                                    await detailViewModel.saveChanges()
                                }
                            }
                            .disabled(!detailViewModel.hasChanges)

                            Button("Cancel", role: .cancel) {
                                detailViewModel.cancelEditing()
                            }
                        } else {
                            Button {
                                detailViewModel.startEditing()
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button {
                                detailViewModel.exportActivity()
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                historyViewModel.requestDelete(detailViewModel.activity)
                                dismiss()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var metricsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricCard(
                    title: "Distance",
                    value: String(format: "%.2f", detailViewModel.activity.distance / distanceUnit.metersPerUnit),
                    unit: distanceUnit.abbreviation,
                    icon: "arrow.left.and.right"
                )

                MetricCard(
                    title: "Duration",
                    value: durationValue,
                    unit: durationUnit,
                    icon: "clock"
                )
            }

            HStack(spacing: 12) {
                MetricCard(
                    title: "Pace",
                    value: paceValue,
                    unit: "/\(distanceUnit.abbreviation)",
                    icon: "speedometer"
                )

                MetricCard(
                    title: "Elevation",
                    value: String(format: "%.0f", detailViewModel.activity.elevationGain),
                    unit: "m",
                    icon: "arrow.up.right"
                )
            }
        }
        .padding(.horizontal)
    }

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Splits")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(detailViewModel.activity.splits.enumerated()), id: \.element.id) { index, split in
                    HStack {
                        Text("\(distanceUnit == .kilometers ? "km" : "mi") \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(split.formattedPace(unit: distanceUnit))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if split.elevationGain > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.caption2)
                                Text(String(format: "%.0fm", split.elevationGain))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(index % 2 == 0 ? Color(.secondarySystemGroupedBackground) : Color(.systemGroupedBackground))
                }
            }
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var paceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pace")
                .font(.headline)
                .padding(.horizontal)

            Chart(detailViewModel.paceData, id: \.distance) { item in
                LineMark(
                    x: .value("Distance", item.distance),
                    y: .value("Pace", item.pace / 60.0)
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Distance", item.distance),
                    y: .value("Pace", item.pace / 60.0)
                )
                .foregroundStyle(.orange.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var elevationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elevation")
                .font(.headline)
                .padding(.horizontal)

            Chart(detailViewModel.elevationData, id: \.distance) { item in
                LineMark(
                    x: .value("Distance", item.distance),
                    y: .value("Elevation", item.elevation)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Distance", item.distance),
                    y: .value("Elevation", item.elevation)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)

                if detailViewModel.isEditing {
                    Spacer()
                    Text("Editing")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            if detailViewModel.isEditing {
                TextEditor(text: $detailViewModel.editedNotes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
                    .padding(.horizontal)
            } else if let notes = detailViewModel.activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                Text("No notes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Info")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                infoRow(label: "Date", value: detailViewModel.formattedDate)
                Divider()
                infoRow(label: "Type", value: detailViewModel.activity.type.displayName)
                Divider()
                infoRow(label: "Distance", value: detailViewModel.formattedDistance(unit: distanceUnit))
                Divider()
                infoRow(label: "Duration", value: detailViewModel.activity.formattedDuration)
                Divider()
                infoRow(label: "Avg Pace", value: detailViewModel.formattedPace(unit: distanceUnit))
                Divider()
                infoRow(label: "Elevation Gain", value: detailViewModel.formattedElevationGain)
                Divider()
                infoRow(label: "Elevation Loss", value: detailViewModel.formattedElevationLoss)
                Divider()
                infoRow(label: "Splits", value: "\(detailViewModel.splitCount)")
                Divider()
                infoRow(label: "GPS Points", value: "\(detailViewModel.locationCount)")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Computed Properties

    private var durationValue: String {
        let hours = Int(detailViewModel.activity.duration) / 3600
        let minutes = (Int(detailViewModel.activity.duration) % 3600) / 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)"
        }
    }

    private var durationUnit: String {
        let hours = Int(detailViewModel.activity.duration) / 3600
        return hours > 0 ? "h" : "min"
    }

    private var paceValue: String {
        let minutes = Int(detailViewModel.activity.averagePace) / 60
        let seconds = Int(detailViewModel.activity.averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Route Map View

struct ActivityRouteMapView: View {
    let routeCoordinates: [CLLocationCoordinate2D]
    let center: CLLocationCoordinate2D
    let span: Double

    @State private var region: MKCoordinateRegion

    init(routeCoordinates: [CLLocationCoordinate2D], center: CLLocationCoordinate2D, span: Double) {
        self.routeCoordinates = routeCoordinates
        self.center = center
        self.span = span
        self._region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: []) { _ in
            MapPin(coordinate: center)
        }
        .overlay(
            RouteOverlay(coordinates: routeCoordinates)
        )
        .disabled(true)
    }
}

struct RouteOverlay: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        // Simple overlay - full route drawing would require UIViewRepresentable
        EmptyView()
    }
}

// MARK: - Preview

#Preview {
    ActivityDetailView(
        activity: Activity(
            type: .run,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            distance: 5240,
            duration: 1800,
            elevationGain: 120,
            elevationLoss: 115,
            averagePace: 343,
            notes: "Great morning run!",
            locations: [],
            splits: [
                Split(distance: 1000, duration: 343, pace: 343, elevationGain: 30),
                Split(distance: 1000, duration: 338, pace: 338, elevationGain: 25),
                Split(distance: 1000, duration: 350, pace: 350, elevationGain: 35),
                Split(distance: 1000, duration: 345, pace: 345, elevationGain: 20),
                Split(distance: 1000, duration: 340, pace: 340, elevationGain: 10)
            ]
        ),
        viewModel: HistoryViewModel()
    )
}

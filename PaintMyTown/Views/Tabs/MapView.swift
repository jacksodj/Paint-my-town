//
//  MapView.swift
//  PaintMyTown
//
//  Main view for the Map tab - coverage visualization
//

import SwiftUI
import MapKit

/// Main view for the Map tab - coverage visualization
struct MapView: View {
    @ObservedObject var coordinator: MapCoordinator
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CoverageMapViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                // Map view
                CoverageMapContentView(viewModel: viewModel)
                    .ignoresSafeArea(edges: .top)

                // Overlay UI
                VStack {
                    Spacer()

                    // Statistics card
                    if let stats = viewModel.statistics {
                        StatisticsCard(
                            stats: stats,
                            formattedArea: viewModel.formattedArea()
                        )
                        .padding()
                        .transition(.move(edge: .bottom))
                    }
                }

                // Loading overlay
                if viewModel.isLoading {
                    LoadingOverlay(progress: viewModel.progress)
                }
            }
            .navigationTitle("Coverage Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach([CoverageAlgorithmType.areaFill, .heatmap, .routeLines], id: \.self) { type in
                            Button(action: {
                                Task {
                                    await viewModel.changeVisualizationType(type)
                                }
                            }) {
                                Label(type.displayName, systemImage: type.iconName)
                                if viewModel.visualizationType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "map")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Filter button
                        Button(action: {
                            viewModel.showFilterSheet = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle")

                                // Badge for active filters
                                if viewModel.activeFilterCount() > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }

                        // Refresh button
                        Button(action: {
                            Task {
                                await viewModel.refresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheetView(
                    filter: $viewModel.activeFilter,
                    onApply: { filter in
                        Task {
                            await viewModel.applyFilter(filter)
                        }
                    },
                    onClear: {
                        Task {
                            await viewModel.clearFilter()
                        }
                    }
                )
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Coverage Map Content

private struct CoverageMapContentView: View {
    @ObservedObject var viewModel: CoverageMapViewModel

    var body: some View {
        if #available(iOS 17.0, *) {
            Map(
                coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true
            )
            .mapStyle(viewModel.mapType.mapStyle)
        } else {
            Map(
                coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true
            )
        }
    }
}

// MARK: - Statistics Card

private struct StatisticsCard: View {
    let stats: CoverageStatistics
    let formattedArea: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                StatisticItem(
                    title: "Area Covered",
                    value: formattedArea,
                    icon: "map.fill"
                )

                Divider()
                    .frame(height: 40)

                StatisticItem(
                    title: "Locations",
                    value: "\(stats.totalTiles)",
                    icon: "location.fill"
                )

                Divider()
                    .frame(height: 40)

                StatisticItem(
                    title: "Visits",
                    value: "\(stats.totalVisits)",
                    icon: "figure.walk"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

private struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.title3)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading Overlay

private struct LoadingOverlay: View {
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                if progress > 0 && progress < 1 {
                    Text("Calculating coverage...")
                        .foregroundColor(.white)
                        .font(.subheadline)

                    ProgressView(value: progress)
                        .frame(width: 200)
                        .tint(.white)
                } else {
                    Text("Loading...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

// MARK: - Extensions

@available(iOS 17.0, *)
private extension MKMapType {
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard
        case .satellite:
            return .imagery
        case .hybrid:
            return .hybrid
        default:
            return .standard
        }
    }
}

private extension CoverageAlgorithmType {
    var iconName: String {
        switch self {
        case .areaFill:
            return "square.grid.3x3.fill"
        case .heatmap:
            return "map.fill"
        case .routeLines:
            return "timeline"
        }
    }
}

// MARK: - Preview

#Preview {
    MapView(coordinator: MapCoordinator(appState: AppState.shared))
        .environmentObject(AppState.shared)
}

//
//  MapView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI
import MapKit

/// Main view for the Map tab - coverage visualization
/// TODO: Full implementation in M2 (Coverage & Filters)
struct MapView: View {
    @ObservedObject var coordinator: MapCoordinator
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Placeholder icon
                    Image(systemName: "map")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    // Title
                    Text("Coverage Map")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Description
                    Text("Visualize all the places you've explored")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Feature list
                    VStack(alignment: .leading, spacing: 12) {
                        MapFeatureRow(icon: "map.fill", text: "Heatmap visualization")
                        MapFeatureRow(icon: "square.grid.3x3.fill", text: "Area fill coverage")
                        MapFeatureRow(icon: "line.3.horizontal.decrease.circle", text: "Advanced filters")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Coming soon badge
                    Text("Coming in M2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.top, 8)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        coordinator.showFilterSheet()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(true)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct MapFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MapView(coordinator: MapCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

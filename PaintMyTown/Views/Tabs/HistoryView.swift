//
//  HistoryView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Main view for the History tab - activity list
/// TODO: Full implementation in M3 (History & UI Polish)
struct HistoryView: View {
    @ObservedObject var coordinator: HistoryCoordinator
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
                    Image(systemName: "list.bullet")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    // Title
                    Text("Activity History")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Description
                    Text("View and analyze your past workouts")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Empty state
                    VStack(spacing: 12) {
                        Text("No activities yet")
                            .font(.headline)
                        Text("Start recording workouts to see them here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Coming soon badge
                    Text("Coming in M3")
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        coordinator.showSearchSheet()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .disabled(true)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView(coordinator: HistoryCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

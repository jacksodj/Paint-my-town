//
//  RecordView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Main view for the Record tab - workout tracking interface
/// TODO: Full implementation in M1 (Recording Engine)
struct RecordView: View {
    @ObservedObject var coordinator: RecordCoordinator
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
                    Image(systemName: "figure.walk")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    // Title
                    Text("Record")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Description
                    Text("Track your walks, runs, and bike rides")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Stub button
                    Button(action: {
                        // TODO: Implement in M1
                        coordinator.startWorkout(type: .walk)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(true)

                    // Coming soon badge
                    Text("Coming in M1")
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
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    RecordView(coordinator: RecordCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

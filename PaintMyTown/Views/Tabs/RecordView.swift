//
//  RecordView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI
import CoreLocation

/// Main view for the Record tab - workout tracking interface
struct RecordView: View {
    @ObservedObject var coordinator: RecordCoordinator
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = RecordViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isWorkoutActive {
                    // Active workout interface
                    activeWorkoutView
                } else {
                    // Pre-workout interface
                    preWorkoutView
                }
            }
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showWorkoutSummary) {
                if let activity = viewModel.completedWorkout {
                    WorkoutSummaryView(
                        activity: activity,
                        onSave: {
                            // Activity already saved by endWorkout()
                            viewModel.dismissSummary()
                        },
                        onDiscard: {
                            // TODO: Implement discard logic
                            viewModel.dismissSummary()
                        }
                    )
                }
            }
            .alert("Stop Workout?", isPresented: $viewModel.showStopConfirmation) {
                Button("Continue", role: .cancel) {}
                Button("Stop & Save", role: .destructive) {
                    viewModel.stopWorkout()
                }
            } message: {
                Text("Your workout will be saved and you can view it in your history.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Active Workout View

    @ViewBuilder
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Map at top
            RouteMapView(
                route: $viewModel.currentRoute,
                userLocation: $viewModel.currentLocation
            )
            .frame(height: 280)

            // Metrics
            ScrollView {
                VStack(spacing: 16) {
                    // Primary metrics (2x2 grid)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        MetricCard(
                            title: "Distance",
                            value: viewModel.formattedDistance,
                            unit: viewModel.distanceUnit,
                            icon: "arrow.left.and.right"
                        )

                        MetricCard(
                            title: "Duration",
                            value: viewModel.formattedDuration,
                            unit: "",
                            icon: "clock"
                        )

                        MetricCard(
                            title: "Pace",
                            value: viewModel.formattedPace,
                            unit: viewModel.paceUnit,
                            icon: "speedometer"
                        )

                        MetricCard(
                            title: "Elevation",
                            value: viewModel.formattedElevation,
                            unit: "",
                            icon: "arrow.up.right"
                        )
                    }
                    .padding(.horizontal)

                    // Control buttons
                    controlButtons
                        .padding()

                    // Status indicator
                    if viewModel.isWorkoutPaused {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                            Text("Paused")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.vertical)
            }
        }
    }

    // MARK: - Pre-Workout View

    @ViewBuilder
    private var preWorkoutView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: activityIcon(for: viewModel.selectedActivityType))
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                Text("Ready to \(viewModel.selectedActivityType.displayName)?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose your activity type and start tracking")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Activity type selector
            ActivityTypeSelector(selectedType: $viewModel.selectedActivityType)
                .padding(.top)

            // Start button
            WorkoutControlButton(type: .start) {
                viewModel.startWorkout()
            }
            .padding(.top)

            // Permission status
            if !appState.isLocationAuthorized {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Location permission required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Control Buttons

    @ViewBuilder
    private var controlButtons: some View {
        HStack(spacing: 24) {
            // Pause/Resume button
            if viewModel.isWorkoutPaused {
                WorkoutControlButton(type: .resume) {
                    viewModel.resumeWorkout()
                }
            } else {
                WorkoutControlButton(type: .pause) {
                    viewModel.pauseWorkout()
                }
            }

            // Stop button
            WorkoutControlButton(type: .stop) {
                viewModel.requestStopWorkout()
            }
        }
    }

    // MARK: - Helpers

    private func activityIcon(for type: ActivityType) -> String {
        switch type {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .bike: return "bicycle"
        }
    }
}

// MARK: - Preview

#Preview("Pre-Workout") {
    RecordView(coordinator: RecordCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

#Preview("Active Workout") {
    let view = RecordView(coordinator: RecordCoordinator(appState: .shared))
    view.environmentObject(AppState.shared)
    return view
}

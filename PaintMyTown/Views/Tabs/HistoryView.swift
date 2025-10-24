//
//  HistoryView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Main view for the History tab - activity list
struct HistoryView: View {
    @ObservedObject var coordinator: HistoryCoordinator
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()

    @State private var showSortOptions = false
    @State private var showFilterOptions = false

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if viewModel.isEmpty && viewModel.searchText.isEmpty && viewModel.filterType == nil {
                    emptyStateView
                } else {
                    activityListView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search activities")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(ActivitySortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.filterType = nil
                        } label: {
                            HStack {
                                Text("All Activities")
                                if viewModel.filterType == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        ForEach([ActivityType.walk, .run, .bike], id: \.self) { type in
                            Button {
                                viewModel.filterType = type
                            } label: {
                                HStack {
                                    Text(type.displayName)
                                    if viewModel.filterType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showActivityDetail) {
                if let activity = viewModel.selectedActivity {
                    ActivityDetailView(activity: activity, viewModel: viewModel)
                }
            }
            .alert("Delete Activity", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }
            .task {
                await viewModel.loadActivities()
            }
        }
    }

    // MARK: - Subviews

    private var activityListView: some View {
        List {
            // Statistics Section
            if !viewModel.activities.isEmpty {
                Section {
                    statsHeaderView
                }
            }

            // Activities Section
            Section {
                if viewModel.filteredActivities.isEmpty {
                    emptySearchView
                } else {
                    ForEach(viewModel.filteredActivities) { activity in
                        Button {
                            viewModel.selectActivity(activity)
                        } label: {
                            ActivityRowView(activity: activity)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.requestDelete(activity)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                if !viewModel.filteredActivities.isEmpty {
                    Text("\(viewModel.filteredActivities.count) \(viewModel.filteredActivities.count == 1 ? "Activity" : "Activities")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refreshActivities()
        }
    }

    private var statsHeaderView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.totalActivities)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.formattedTotalDistance)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.formattedTotalDuration)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            // Title
            Text("No Activities Yet")
                .font(.title2)
                .fontWeight(.bold)

            // Description
            Text("Start recording workouts to see them here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.headline)

            Text("Try adjusting your search or filters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("With Activities") {
    let appState = AppState.shared
    return HistoryView(coordinator: HistoryCoordinator(appState: appState))
        .environmentObject(appState)
}

#Preview("Empty State") {
    HistoryView(coordinator: HistoryCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

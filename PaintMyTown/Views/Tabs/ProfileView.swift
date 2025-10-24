//
//  ProfileView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Main view for the Profile tab - user profile and settings
/// TODO: Full implementation in M5 (HealthKit & Import)
struct ProfileView: View {
    @ObservedObject var coordinator: ProfileCoordinator
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            List {
                // Profile section
                Section {
                    HStack(spacing: 16) {
                        // Avatar placeholder
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Profile")
                                .font(.headline)
                            Text("Explore your fitness journey")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats section
                Section("Stats") {
                    StatRow(icon: "figure.walk", label: "Total Activities", value: "0")
                    StatRow(icon: "map", label: "Area Covered", value: "0 km²")
                    StatRow(icon: "calendar", label: "Active Days", value: "0")
                }

                // Settings section
                Section("Settings") {
                    NavigationLink(destination: Text("Settings")) {
                        Label("App Settings", systemImage: "gear")
                    }
                    .disabled(true)

                    Button(action: {
                        coordinator.showPermissions()
                    }) {
                        Label("Permissions", systemImage: "lock.shield")
                    }
                    .disabled(true)

                    Button(action: {
                        coordinator.showDataManagement()
                    }) {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                    .disabled(true)
                }

                // About section
                Section("About") {
                    Button(action: {
                        coordinator.showAbout()
                    }) {
                        Label("About Paint My Town", systemImage: "info.circle")
                    }
                    .disabled(true)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                // Coming soon badge
                Section {
                    HStack {
                        Spacer()
                        Text("Full features coming in M5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Supporting Views

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView(coordinator: ProfileCoordinator(appState: .shared))
        .environmentObject(AppState.shared)
}

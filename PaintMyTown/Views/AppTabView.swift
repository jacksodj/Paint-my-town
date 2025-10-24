//
//  AppTabView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Main tab bar view coordinating all app tabs
struct AppTabView: View {
    @ObservedObject var coordinator: AppCoordinator
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Record Tab
            RecordView(coordinator: coordinator.recordCoordinator)
                .tabItem {
                    Label(Tab.record.title, systemImage: coordinator.selectedTab == .record ? Tab.record.iconFilled : Tab.record.icon)
                }
                .tag(Tab.record)

            // Map Tab
            MapView(coordinator: coordinator.mapCoordinator)
                .tabItem {
                    Label(Tab.map.title, systemImage: coordinator.selectedTab == .map ? Tab.map.iconFilled : Tab.map.icon)
                }
                .tag(Tab.map)

            // History Tab
            HistoryView(coordinator: coordinator.historyCoordinator)
                .tabItem {
                    Label(Tab.history.title, systemImage: coordinator.selectedTab == .history ? Tab.history.iconFilled : Tab.history.icon)
                }
                .tag(Tab.history)

            // Profile Tab
            ProfileView(coordinator: coordinator.profileCoordinator)
                .tabItem {
                    Label(Tab.profile.title, systemImage: coordinator.selectedTab == .profile ? Tab.profile.iconFilled : Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(.accentColor)
    }
}

// MARK: - Preview

#Preview {
    @MainActor func makePreview() -> some View {
        let coordinator = AppCoordinator(appState: AppState.shared)
        coordinator.start()
        return AppTabView(coordinator: coordinator)
            .environmentObject(AppState.shared)
    }
    return makePreview()
}

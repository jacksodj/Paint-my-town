import SwiftUI

@main
struct PaintMyTownApp: App {
    // MARK: - Properties

    @StateObject private var appState = AppState.shared
    @StateObject private var appCoordinator: AppCoordinator

    // MARK: - Initialization

    init() {
        // Initialize the app coordinator
        let coordinator = AppCoordinator(appState: .shared)
        coordinator.start() // Register dependencies before views are created
        _appCoordinator = StateObject(wrappedValue: coordinator)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            AppTabView(coordinator: appCoordinator)
                .environmentObject(appState)
                .onChange(of: appState.currentError) { error in
                    // Handle app-level errors
                    if let error = error {
                        Logger.shared.error("App error: \(error.errorDescription ?? "Unknown")", category: .general)
                    }
                }
                .errorAlert(error: Binding(
                    get: { appState.currentError },
                    set: { appState.currentError = $0 }
                ))
        }
    }
}

//
//  ErrorView.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// A reusable view for displaying errors to users
struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: 50))
                .foregroundColor(.red)

            // Error title
            Text("Something Went Wrong")
                .font(.title2)
                .fontWeight(.bold)

            // Error description
            if let description = error.errorDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // Action buttons
            VStack(spacing: 12) {
                // Retry button
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                // Settings button for permission errors
                if needsSettingsButton {
                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var errorIcon: String {
        switch error {
        case .locationPermissionDenied, .locationPermissionRestricted, .locationUnavailable:
            return "location.slash.fill"
        case .permissionDenied, .permissionRestricted:
            return "exclamationmark.shield.fill"
        case .networkUnavailable, .networkTimeout, .networkFailed:
            return "wifi.slash"
        case .databaseCorrupted, .databaseReadFailed, .databaseWriteFailed:
            return "externaldrive.badge.exclamationmark"
        case .healthKitNotAvailable, .healthKitPermissionDenied:
            return "heart.slash.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    private var needsSettingsButton: Bool {
        switch error {
        case .locationPermissionDenied, .locationPermissionRestricted,
             .permissionDenied, .permissionRestricted,
             .healthKitPermissionDenied:
            return true
        default:
            return false
        }
    }

    // MARK: - Actions

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Error Alert Extension

extension View {
    /// Presents an error alert when an error is present
    func errorAlert(error: Binding<AppError?>, retryAction: (() -> Void)? = nil) -> some View {
        alert(error.wrappedValue?.errorDescription ?? "Error", isPresented: .constant(error.wrappedValue != nil)) {
            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
            }

            if let currentError = error.wrappedValue, needsSettingsButton(for: currentError) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: {
            if let suggestion = error.wrappedValue?.recoverySuggestion {
                Text(suggestion)
            }
        }
    }

    private func needsSettingsButton(for error: AppError) -> Bool {
        switch error {
        case .locationPermissionDenied, .locationPermissionRestricted,
             .permissionDenied, .permissionRestricted,
             .healthKitPermissionDenied:
            return true
        default:
            return false
        }
    }
}

// MARK: - Preview

#Preview("Location Error") {
    ErrorView(error: .locationPermissionDenied) {
        print("Retry tapped")
    }
}

#Preview("Database Error") {
    ErrorView(error: .databaseCorrupted)
}

#Preview("Network Error") {
    ErrorView(error: .networkUnavailable) {
        print("Retry tapped")
    }
}

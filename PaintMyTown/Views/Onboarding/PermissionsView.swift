//
//  PermissionsView.swift
//  PaintMyTown
//
//  Onboarding view for requesting app permissions
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var permissionManager = PermissionManager()
    @State private var selectedPermission: Permission?
    @State private var showingDetail = false
    @State private var isRequestingPermission = false

    var onComplete: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.45),
                        Color(red: 0.2, green: 0.3, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Permission cards
                        VStack(spacing: 16) {
                            PermissionCard(
                                permission: .location,
                                state: permissionManager.locationState,
                                rationale: permissionManager.permissionRationale(for: .location),
                                onLearnMore: {
                                    selectedPermission = .location
                                    showingDetail = true
                                },
                                onRequest: {
                                    await requestPermission(.location)
                                }
                            )

                            PermissionCard(
                                permission: .motion,
                                state: permissionManager.motionState,
                                rationale: permissionManager.permissionRationale(for: .motion),
                                onLearnMore: {
                                    selectedPermission = .motion
                                    showingDetail = true
                                },
                                onRequest: {
                                    await requestPermission(.motion)
                                }
                            )

                            PermissionCard(
                                permission: .healthKit,
                                state: permissionManager.healthKitState,
                                rationale: permissionManager.permissionRationale(for: .healthKit),
                                onLearnMore: {
                                    selectedPermission = .healthKit
                                    showingDetail = true
                                },
                                onRequest: {
                                    await requestPermission(.healthKit)
                                }
                            )
                        }
                        .padding(.horizontal)

                        // Continue button
                        if allRequiredPermissionsGranted {
                            Button(action: {
                                onComplete?()
                            }) {
                                Text("Get Started")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }

                        // Skip for now (for optional permissions)
                        if !allRequiredPermissionsGranted && somePermissionsGranted {
                            Button(action: {
                                onComplete?()
                            }) {
                                Text("Continue Without All Permissions")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDetail) {
                if let permission = selectedPermission {
                    PermissionDetailView(
                        permission: permission,
                        permissionManager: permissionManager
                    )
                }
            }
            .overlay {
                if isRequestingPermission {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundColor(.white)
                .padding(.bottom, 8)

            Text("Paint the Town")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            Text("To track your activities and map your adventures, Paint the Town needs a few permissions.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Computed Properties

    private var allRequiredPermissionsGranted: Bool {
        // Location is required, others are optional
        permissionManager.locationState.isAuthorized
    }

    private var somePermissionsGranted: Bool {
        permissionManager.locationState.isAuthorized ||
        permissionManager.motionState.isAuthorized ||
        permissionManager.healthKitState.isAuthorized
    }

    // MARK: - Actions

    private func requestPermission(_ permission: Permission) async {
        isRequestingPermission = true

        let result: PermissionState
        switch permission {
        case .location:
            result = await permissionManager.requestLocationPermission()
        case .motion:
            result = await permissionManager.requestMotionPermission()
        case .healthKit:
            result = await permissionManager.requestHealthKitPermission()
        }

        isRequestingPermission = false

        // If permission was denied, we could show an alert here
        if result == .denied {
            // Could show alert explaining how to enable in Settings
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let permission: Permission
    let state: PermissionState
    let rationale: String
    let onLearnMore: () -> Void
    let onRequest: () async -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack(spacing: 16) {
                Image(systemName: permission.icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.2))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(permission.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(stateText)
                        .font(.caption)
                        .foregroundColor(stateColor)
                }

                Spacer()

                statusIcon
            }

            // Rationale
            Text(rationale)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            HStack(spacing: 12) {
                Button(action: onLearnMore) {
                    Text("Learn More")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()

                actionButton
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        case .denied:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.title2)
        case .restricted:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
        case .notDetermined:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .notDetermined:
            Button(action: {
                Task {
                    isRequesting = true
                    await onRequest()
                    isRequesting = false
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Allow")
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 80)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isRequesting)

        case .denied, .restricted:
            Button(action: {
                PermissionManager().openSettings()
            }) {
                Text("Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

        case .authorized:
            EmptyView()
        }
    }

    // MARK: - Computed Properties

    private var iconColor: Color {
        switch state {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .blue
        }
    }

    private var stateColor: Color {
        switch state {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .secondary
        }
    }

    private var stateText: String {
        switch state {
        case .notDetermined:
            return "Not requested"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }
}

// MARK: - Preview

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
    }
}

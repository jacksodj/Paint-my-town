//
//  PermissionDetailView.swift
//  PaintMyTown
//
//  Detailed explanation view for individual permissions
//

import SwiftUI

struct PermissionDetailView: View {
    let permission: Permission
    @ObservedObject var permissionManager: PermissionManager

    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header with large icon
                    headerSection

                    // What we do section
                    whatWeDoSection

                    // What we don't do section
                    whatWeDontDoSection

                    // Privacy section
                    privacySection

                    // Current status
                    statusSection

                    Spacer(minLength: 32)
                }
                .padding(24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(permission.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: permission.icon)
                .font(.system(size: 72))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)

            Text(permissionManager.permissionRationale(for: permission))
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
    }

    // MARK: - What We Do Section

    private var whatWeDoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "checkmark.circle.fill",
                title: "What We Do",
                color: .green
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(whatWeDoItems, id: \.self) { item in
                    FeatureRow(icon: "checkmark", text: item, color: .green)
                }
            }
        }
    }

    // MARK: - What We Don't Do Section

    private var whatWeDontDoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "xmark.circle.fill",
                title: "What We Don't Do",
                color: .red
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(whatWeDontDoItems, id: \.self) { item in
                    FeatureRow(icon: "xmark", text: item, color: .red)
                }
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "lock.shield.fill",
                title: "Your Privacy",
                color: .blue
            )

            Text(privacyText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 16) {
            // Current status
            HStack {
                Text("Current Status:")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            // Action button
            actionButton
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
            Text(statusText)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch currentState {
        case .notDetermined:
            Button(action: {
                Task {
                    isRequesting = true
                    await requestPermission()
                    isRequesting = false
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Allow \(permission.title)")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRequesting)

        case .denied, .restricted:
            VStack(spacing: 12) {
                Text("Permission is currently \(statusText.lowercased()). You can enable it in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    permissionManager.openSettings()
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Open Settings")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

        case .authorized:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Permission granted")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Computed Properties

    private var currentState: PermissionState {
        switch permission {
        case .location:
            return permissionManager.locationState
        case .motion:
            return permissionManager.motionState
        case .healthKit:
            return permissionManager.healthKitState
        }
    }

    private var statusIcon: String {
        switch currentState {
        case .notDetermined:
            return "questionmark.circle.fill"
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusText: String {
        switch currentState {
        case .notDetermined:
            return "Not Requested"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }

    private var statusColor: Color {
        switch currentState {
        case .notDetermined:
            return .gray
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        }
    }

    private var whatWeDoItems: [String] {
        switch permission {
        case .location:
            return [
                "Track your route during workouts",
                "Calculate distance and pace in real-time",
                "Create maps showing where you've explored",
                "Continue tracking when app is in background",
                "Store your location data locally on your device"
            ]
        case .motion:
            return [
                "Detect when you pause during a workout",
                "Automatically pause tracking when you stop",
                "Resume tracking when you start moving",
                "Improve distance and pace accuracy",
                "Detect different types of activity"
            ]
        case .healthKit:
            return [
                "Save workouts to the Health app",
                "Store workout routes in Health",
                "Read your workout history",
                "Sync data across your Apple devices",
                "Integrate with other fitness apps"
            ]
        }
    }

    private var whatWeDontDoItems: [String] {
        switch permission {
        case .location:
            return [
                "Track your location when not recording a workout",
                "Share your location with third parties",
                "Sell your location data",
                "Use location for advertising",
                "Upload location without your consent"
            ]
        case .motion:
            return [
                "Track motion when not in an active workout",
                "Access motion data outside of workouts",
                "Share motion data with third parties",
                "Use motion data for any other purpose",
                "Store motion data long-term"
            ]
        case .healthKit:
            return [
                "Access health data without permission",
                "Share your health data with anyone",
                "Use health data for advertising",
                "Sync to cloud without your consent",
                "Require HealthKit to use the app"
            ]
        }
    }

    private var privacyText: String {
        switch permission {
        case .location:
            return "Your location data is stored securely on your device. We never upload your location to our servers without your explicit consent. You can delete all location data at any time from the app settings."
        case .motion:
            return "Motion data is used only during active workouts to improve tracking accuracy. We don't store motion data long-term, and it never leaves your device. This permission is optional and the app works without it."
        case .healthKit:
            return "HealthKit data stays in Apple's secure Health app. We only read or write the specific workout types you authorize. This permission is completely optional and the app provides full functionality without it."
        }
    }

    // MARK: - Actions

    private func requestPermission() async {
        switch permission {
        case .location:
            _ = await permissionManager.requestLocationPermission()
        case .motion:
            _ = await permissionManager.requestMotionPermission()
        case .healthKit:
            _ = await permissionManager.requestHealthKitPermission()
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

struct PermissionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionDetailView(
            permission: .location,
            permissionManager: PermissionManager()
        )
    }
}

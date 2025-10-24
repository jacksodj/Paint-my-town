//
//  ActivityRowView.swift
//  PaintMyTown
//
//  Created on 2025-10-24.
//

import SwiftUI

/// Row view for displaying an activity summary in a list
struct ActivityRowView: View {
    let activity: Activity
    let distanceUnit: DistanceUnit

    init(activity: Activity, distanceUnit: DistanceUnit = UserDefaultsManager.shared.distanceUnit) {
        self.activity = activity
        self.distanceUnit = distanceUnit
    }

    var body: some View {
        HStack(spacing: 12) {
            // Activity type icon
            activityIcon
                .frame(width: 50, height: 50)
                .background(activityColor.opacity(0.1))
                .cornerRadius(10)

            // Activity details
            VStack(alignment: .leading, spacing: 6) {
                // Activity type and date
                HStack {
                    Text(activity.type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Distance and duration
                HStack(spacing: 16) {
                    Label {
                        Text(formattedDistance)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label {
                        Text(activity.formattedDuration)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Pace
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(activity.formattedPace(unit: distanceUnit))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Computed Properties

    private var activityIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 24))
            .foregroundColor(activityColor)
    }

    private var iconName: String {
        switch activity.type {
        case .walk:
            return "figure.walk"
        case .run:
            return "figure.run"
        case .bike:
            return "bicycle"
        }
    }

    private var activityColor: Color {
        switch activity.type {
        case .walk:
            return .green
        case .run:
            return .orange
        case .bike:
            return .blue
        }
    }

    private var formattedDistance: String {
        let value = activity.distance / distanceUnit.metersPerUnit
        return String(format: "%.2f %@", value, distanceUnit.abbreviation)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(activity.startDate) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: activity.startDate))"
        } else if calendar.isDateInYesterday(activity.startDate) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: activity.startDate))"
        } else if calendar.isDate(activity.startDate, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }

        return formatter.string(from: activity.startDate)
    }
}

// MARK: - Preview

#Preview("Walk Activity") {
    ActivityRowView(
        activity: Activity(
            type: .walk,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            distance: 5240,
            duration: 3600,
            elevationGain: 50,
            elevationLoss: 45,
            averagePace: 686,
            notes: "Morning walk"
        ),
        distanceUnit: .kilometers
    )
    .padding()
}

#Preview("Run Activity") {
    ActivityRowView(
        activity: Activity(
            type: .run,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(-84000),
            distance: 10500,
            duration: 2400,
            elevationGain: 120,
            elevationLoss: 115,
            averagePace: 228,
            notes: "Evening run"
        ),
        distanceUnit: .kilometers
    )
    .padding()
}

#Preview("Bike Activity") {
    ActivityRowView(
        activity: Activity(
            type: .bike,
            startDate: Date().addingTimeInterval(-172800),
            endDate: Date().addingTimeInterval(-168000),
            distance: 25000,
            duration: 4800,
            elevationGain: 300,
            elevationLoss: 290,
            averagePace: 192,
            notes: "Weekend bike ride"
        ),
        distanceUnit: .miles
    )
    .padding()
}

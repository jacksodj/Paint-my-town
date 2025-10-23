//
//  MetricCard.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Reusable card component for displaying workout metrics
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            // Icon and title
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Distance") {
    MetricCard(
        title: "Distance",
        value: "5.24",
        unit: "km",
        icon: "arrow.left.and.right"
    )
    .padding()
}

#Preview("Pace") {
    MetricCard(
        title: "Pace",
        value: "5:42",
        unit: "/km",
        icon: "speedometer"
    )
    .padding()
}

#Preview("Duration") {
    MetricCard(
        title: "Duration",
        value: "29:54",
        unit: "",
        icon: "clock"
    )
    .padding()
}

#Preview("Elevation") {
    MetricCard(
        title: "Elevation",
        value: "142",
        unit: "m",
        icon: "arrow.up.right"
    )
    .padding()
}

//
//  ActivityTypeSelector.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Activity type selector component with SF Symbol icons
struct ActivityTypeSelector: View {
    @Binding var selectedType: ActivityType

    var body: some View {
        HStack(spacing: 16) {
            ForEach(ActivityType.allCases, id: \.self) { activityType in
                ActivityTypeButton(
                    activityType: activityType,
                    isSelected: selectedType == activityType
                ) {
                    selectedType = activityType

                    // Haptic feedback
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Individual button for activity type selection
struct ActivityTypeButton: View {
    let activityType: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: isSelected ? 0 : 2)
                    )

                // Label
                Text(activityType.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var iconName: String {
        switch activityType {
        case .walk:
            return "figure.walk"
        case .run:
            return "figure.run"
        case .bike:
            return "bicycle"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // Selected state
        ActivityTypeSelector(selectedType: .constant(.run))

        Divider()

        // All types
        VStack(spacing: 16) {
            ActivityTypeButton(activityType: .walk, isSelected: false) {}
            ActivityTypeButton(activityType: .run, isSelected: true) {}
            ActivityTypeButton(activityType: .bike, isSelected: false) {}
        }
    }
    .padding()
}

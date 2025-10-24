//
//  WorkoutControlButton.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Reusable control button for workout actions (start, pause, resume, stop)
struct WorkoutControlButton: View {
    enum ButtonType {
        case start
        case pause
        case resume
        case stop

        var icon: String {
            switch self {
            case .start: return "play.fill"
            case .pause: return "pause.fill"
            case .resume: return "play.fill"
            case .stop: return "stop.fill"
            }
        }

        var title: String {
            switch self {
            case .start: return "Start"
            case .pause: return "Pause"
            case .resume: return "Resume"
            case .stop: return "Stop"
            }
        }

        var color: Color {
            switch self {
            case .start, .resume: return .green
            case .pause: return .orange
            case .stop: return .red
            }
        }
    }

    let type: ButtonType
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 28, weight: .semibold))

                Text(type.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(width: 100, height: 100)
            .foregroundColor(.white)
            .background(type.color)
            .clipShape(Circle())
            .shadow(color: type.color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Button style that scales on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("All States") {
    VStack(spacing: 32) {
        WorkoutControlButton(type: .start) {
            print("Start")
        }

        WorkoutControlButton(type: .pause) {
            print("Pause")
        }

        WorkoutControlButton(type: .resume) {
            print("Resume")
        }

        WorkoutControlButton(type: .stop) {
            print("Stop")
        }
    }
    .padding()
}

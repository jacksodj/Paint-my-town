//
//  AudioFeedbackService.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import AVFoundation
import Combine

/// Service for providing audio feedback during workouts (split announcements)
final class AudioFeedbackService: NSObject {
    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled: Bool = true
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        loadSettings()
    }

    // MARK: - Public Methods

    /// Enable or disable audio feedback
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaultsManager.shared.voiceAnnouncementEnabled = enabled
    }

    /// Announce a split completion
    func announceSplit(_ split: Split) {
        guard isEnabled else { return }

        let distanceUnit = UserDefaultsManager.shared.distanceUnit

        // Format the announcement
        let distanceText: String
        if split.distance < 1 {
            let meters = Int(split.distance * 1000)
            distanceText = "\(meters) meters"
        } else {
            let distanceFormatted = String(format: "%.1f", split.distance)
            distanceText = "\(distanceFormatted) \(distanceUnit.name)"
        }

        let minutes = Int(split.pace) / 60
        let seconds = Int(split.pace) % 60
        let paceText = "\(minutes) minutes \(seconds) seconds per \(distanceUnit.name)"

        let totalMinutes = Int(split.duration) / 60
        let totalSeconds = Int(split.duration) % 60
        let durationText: String
        if totalMinutes > 0 {
            durationText = "\(totalMinutes) minutes \(totalSeconds) seconds"
        } else {
            durationText = "\(totalSeconds) seconds"
        }

        let announcement = "Split completed. Distance: \(distanceText). Time: \(durationText). Pace: \(paceText)."

        speak(announcement)

        Logger.shared.info("Audio feedback: \(announcement)", category: .workout)
    }

    /// Announce workout started
    func announceWorkoutStarted(type: ActivityType) {
        guard isEnabled else { return }
        let announcement = "\(type.displayName) started. Good luck!"
        speak(announcement)
    }

    /// Announce workout paused
    func announceWorkoutPaused() {
        guard isEnabled else { return }
        let announcement = "Workout paused."
        speak(announcement)
    }

    /// Announce workout resumed
    func announceWorkoutResumed() {
        guard isEnabled else { return }
        let announcement = "Workout resumed."
        speak(announcement)
    }

    /// Announce workout completed
    func announceWorkoutCompleted(distance: Double, duration: TimeInterval) {
        guard isEnabled else { return }

        let distanceUnit = UserDefaultsManager.shared.distanceUnit
        let distanceValue = distance / distanceUnit.metersPerUnit
        let distanceFormatted = String(format: "%.2f", distanceValue)

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        let announcement = "Workout complete. Total distance: \(distanceFormatted) \(distanceUnit.name). Total time: \(minutes) minutes \(seconds) seconds."
        speak(announcement)
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.shared.error("Failed to setup audio session: \(error)", category: .general)
        }
    }

    private func loadSettings() {
        isEnabled = UserDefaultsManager.shared.voiceAnnouncementEnabled
    }

    private func speak(_ text: String) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower than normal
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioFeedbackService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Logger.shared.debug("Started speaking")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Logger.shared.debug("Finished speaking")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Logger.shared.debug("Cancelled speaking")
    }
}

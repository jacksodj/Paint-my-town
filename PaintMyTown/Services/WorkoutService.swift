//
//  WorkoutService.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreLocation
import Combine

/// Manages workout lifecycle, real-time metrics, and data persistence
final class WorkoutService: WorkoutServiceProtocol {
    // MARK: - Properties

    private(set) var activeWorkout: ActiveWorkout?

    // MARK: - Publishers

    var activeWorkoutPublisher: AnyPublisher<ActiveWorkout?, Never> {
        activeWorkoutSubject.eraseToAnyPublisher()
    }

    var metricsPublisher: AnyPublisher<WorkoutMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let locationService: LocationServiceProtocol
    private let repository: ActivityRepositoryProtocol
    private let appState: AppState

    // MARK: - Private Properties

    private let activeWorkoutSubject = CurrentValueSubject<ActiveWorkout?, Never>(nil)
    private let metricsSubject = PassthroughSubject<WorkoutMetrics, Never>()
    private var cancellables = Set<AnyCancellable>()

    // Split calculator
    private var splitCalculator: SplitCalculator?

    // Location buffering (for memory efficiency)
    private var locationBuffer: [LocationSample] = []
    private let maxBufferSize = 1000
    private let bufferFlushThreshold = 500

    // Auto-pause detection
    private var autoPauseEnabled: Bool
    private var consecutiveSlowLocationCount = 0
    private let autoPauseThreshold = 10 // ~10 seconds
    private let autoPauseSpeedThreshold: Double = 0.5 // m/s

    // Background save timer
    private var backgroundSaveTimer: Timer?
    private let backgroundSaveInterval: TimeInterval = 60.0 // 1 minute

    // Temporary file for crash recovery
    private var tempWorkoutFileURL: URL?

    // MARK: - Initialization

    init(
        locationService: LocationServiceProtocol,
        repository: ActivityRepositoryProtocol,
        appState: AppState,
        autoPauseEnabled: Bool = true
    ) {
        self.locationService = locationService
        self.repository = repository
        self.appState = appState
        self.autoPauseEnabled = autoPauseEnabled

        setupLocationSubscription()
    }

    deinit {
        // Note: Cannot call cleanup() here as it's main-actor isolated
        // Cleanup should be called explicitly before deallocation
    }

    // MARK: - ServiceProtocol

    func initialize() async throws {
        // Check for crash recovery
        await recoverFromCrashIfNeeded()
    }

    func cleanup() {
        stopBackgroundSaveTimer()
        locationBuffer.removeAll()
        cancellables.removeAll()
    }

    // MARK: - WorkoutServiceProtocol

    func startWorkout(type: ActivityType) throws -> ActiveWorkout {
        // Validate state
        guard activeWorkout == nil else {
            throw WorkoutServiceError.workoutAlreadyActive
        }

        guard locationService.isAuthorized else {
            throw WorkoutServiceError.locationServiceUnavailable
        }

        // Create new workout
        let workout = ActiveWorkout(type: type, startDate: Date())
        activeWorkout = workout

        // Initialize split calculator
        let distanceUnit = appState.settings.distanceUnit
        splitCalculator = SplitCalculator(distanceUnit: distanceUnit)

        // Start location tracking
        try locationService.startTracking(activityType: type)

        // Start background save timer
        startBackgroundSaveTimer()

        // Update app state
        Task { @MainActor in
            appState.setActiveWorkout(workout)
        }
        activeWorkoutSubject.send(workout)

        Logger.shared.info("Started workout: \(type.displayName)", category: .workout)

        return workout
    }

    func pauseWorkout() throws {
        guard let workout = activeWorkout else {
            throw WorkoutServiceError.noActiveWorkout
        }

        guard workout.state == .recording else {
            throw WorkoutServiceError.invalidWorkoutState("Cannot pause workout in \(workout.state.displayName) state")
        }

        // Pause workout
        workout.pause()

        // Pause location tracking (reduces accuracy)
        locationService.pauseTracking()

        // Persist current state
        saveTemporaryWorkoutState()

        Logger.shared.info("Paused workout", category: .workout)
    }

    func resumeWorkout() throws {
        guard let workout = activeWorkout else {
            throw WorkoutServiceError.noActiveWorkout
        }

        guard workout.state == .paused else {
            throw WorkoutServiceError.invalidWorkoutState("Cannot resume workout in \(workout.state.displayName) state")
        }

        // Resume workout
        workout.resume()

        // Resume location tracking
        locationService.resumeTracking()

        // Reset auto-pause detection
        consecutiveSlowLocationCount = 0

        Logger.shared.info("Resumed workout", category: .workout)
    }

    func endWorkout() throws -> Activity {
        guard let workout = activeWorkout else {
            throw WorkoutServiceError.noActiveWorkout
        }

        // Stop workout
        workout.stop()

        // Stop location tracking
        locationService.stopTracking()

        // Flush any buffered locations
        flushLocationBuffer()

        // Stop background save timer
        stopBackgroundSaveTimer()

        // Convert to completed activity
        let activity = workout.toActivity()

        // Clean up
        activeWorkout = nil
        splitCalculator = nil
        locationBuffer.removeAll()
        consecutiveSlowLocationCount = 0

        // Update app state
        Task { @MainActor in
            appState.setActiveWorkout(nil)
        }
        activeWorkoutSubject.send(nil)

        // Clean up temporary file
        cleanupTemporaryWorkoutFile()

        Logger.shared.info("Ended workout: \(activity.formattedDistance(unit: .kilometers))", category: .workout)

        return activity
    }

    func cancelWorkout() throws {
        guard activeWorkout != nil else {
            throw WorkoutServiceError.noActiveWorkout
        }

        // Stop location tracking
        locationService.stopTracking()

        // Stop background save timer
        stopBackgroundSaveTimer()

        // Clean up
        activeWorkout = nil
        splitCalculator = nil
        locationBuffer.removeAll()
        consecutiveSlowLocationCount = 0

        // Update app state
        Task { @MainActor in
            appState.setActiveWorkout(nil)
        }
        activeWorkoutSubject.send(nil)

        // Clean up temporary file
        cleanupTemporaryWorkoutFile()

        Logger.shared.info("Cancelled workout", category: .workout)
    }

    // MARK: - Private Methods - Location Handling

    private func setupLocationSubscription() {
        locationService.locationPublisher
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        guard let workout = activeWorkout else { return }
        guard workout.state == .recording else { return }

        // Add location to workout (updates distance, pace, elevation)
        workout.addLocation(location)

        // Buffer location for later persistence
        bufferLocation(location)

        // Process split
        if let splitCalc = splitCalculator {
            if let completedSplit = splitCalc.processLocation(location) {
                workout.splits.append(completedSplit)
                Logger.shared.info("Completed split \(workout.splits.count)", category: .workout)
            }
        }

        // Auto-pause detection
        if autoPauseEnabled && workout.state == .recording {
            detectAndHandleAutoPause(location)
        }

        // Emit metrics update
        metricsSubject.send(workout.metrics)
    }

    private func detectAndHandleAutoPause(_ location: CLLocation) {
        let speed = location.speed >= 0 ? location.speed : 0

        if speed < autoPauseSpeedThreshold {
            consecutiveSlowLocationCount += 1

            if consecutiveSlowLocationCount >= autoPauseThreshold {
                // Auto-pause triggered
                do {
                    try pauseWorkout()
                    Logger.shared.info("Auto-pause triggered", category: .workout)
                } catch {
                    Logger.shared.error("Failed to auto-pause: \(error.localizedDescription)", category: .workout)
                }
            }
        } else {
            // Moving again - reset counter or auto-resume
            if consecutiveSlowLocationCount >= autoPauseThreshold {
                // Was auto-paused, now resume
                do {
                    try resumeWorkout()
                    Logger.shared.info("Auto-resume triggered", category: .workout)
                } catch {
                    Logger.shared.error("Failed to auto-resume: \(error.localizedDescription)", category: .workout)
                }
            }
            consecutiveSlowLocationCount = 0
        }
    }

    // MARK: - Location Buffering (M1-T19)

    private func bufferLocation(_ location: CLLocation) {
        let sample = LocationSample(location: location)
        locationBuffer.append(sample)

        // Flush if buffer is getting full
        if locationBuffer.count >= bufferFlushThreshold {
            flushLocationBuffer()
        }
    }

    private func flushLocationBuffer() {
        guard !locationBuffer.isEmpty else { return }

        // In a real implementation, we would persist these to disk
        // For now, they're already in the ActiveWorkout.locations array
        // This would be where we'd write to a temporary file or database

        Logger.shared.debug("Flushed \(locationBuffer.count) locations from buffer")
        locationBuffer.removeAll()
    }

    // MARK: - Background Save (M1-T20)

    private func startBackgroundSaveTimer() {
        stopBackgroundSaveTimer()

        backgroundSaveTimer = Timer.scheduledTimer(
            withTimeInterval: backgroundSaveInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.performBackgroundSave()
            }
        }
    }

    private func stopBackgroundSaveTimer() {
        backgroundSaveTimer?.invalidate()
        backgroundSaveTimer = nil
    }

    private func performBackgroundSave() {
        guard activeWorkout != nil else { return }

        saveTemporaryWorkoutState()
        Logger.shared.debug("Performed background save")
    }

    // MARK: - Crash Recovery

    private func saveTemporaryWorkoutState() {
        guard let workout = activeWorkout else { return }

        do {
            // Create temp directory if needed
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("active_workout_\(workout.id.uuidString).json")
            tempWorkoutFileURL = tempFile

            // Encode workout state
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(workout.toActivity())

            // Write to file
            try data.write(to: tempFile, options: .atomic)

            Logger.shared.debug("Saved temporary workout state")
        } catch {
            Logger.shared.error("Failed to save temporary workout state: \(error.localizedDescription)", category: .workout)
        }
    }

    private func recoverFromCrashIfNeeded() async {
        let tempDir = FileManager.default.temporaryDirectory

        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            ).filter { $0.lastPathComponent.hasPrefix("active_workout_") }

            for tempFile in tempFiles {
                Logger.shared.info("Found temporary workout file: \(tempFile.lastPathComponent)", category: .workout)

                // In a real implementation, we would prompt the user to recover
                // For now, just log and clean up
                try FileManager.default.removeItem(at: tempFile)
            }
        } catch {
            Logger.shared.error("Failed to check for crash recovery: \(error.localizedDescription)", category: .workout)
        }
    }

    private func cleanupTemporaryWorkoutFile() {
        guard let tempFile = tempWorkoutFileURL else { return }

        do {
            if FileManager.default.fileExists(atPath: tempFile.path) {
                try FileManager.default.removeItem(at: tempFile)
                Logger.shared.debug("Cleaned up temporary workout file")
            }
        } catch {
            Logger.shared.error("Failed to clean up temporary file: \(error.localizedDescription)", category: .workout)
        }

        tempWorkoutFileURL = nil
    }
}

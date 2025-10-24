//
//  ActiveWorkout.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreLocation
import Combine

/// Represents an active workout in progress with comprehensive tracking
class ActiveWorkout: Identifiable, ObservableObject {
    // MARK: - Published Properties

    /// Unique identifier for the workout
    let id: UUID

    /// Type of activity (walk, run, bike)
    let type: ActivityType

    /// Workout start time
    let startDate: Date

    /// Current workout state
    @Published var state: WorkoutState = .recording

    /// Real-time metrics
    @Published var metrics: WorkoutMetrics = WorkoutMetrics()

    /// All paused intervals during this workout
    @Published var pausedIntervals: [PausedInterval] = []

    /// All location samples collected
    @Published var locations: [LocationSample] = []

    /// All splits completed
    @Published var splits: [Split] = []

    // MARK: - Private Properties

    /// Last known location for distance calculation
    private var lastLocation: CLLocation?

    /// Last known elevation for elevation tracking
    private var lastElevation: Double?

    /// Locations used for current pace calculation (last 30 seconds or 200m)
    private var recentLocations: [(location: CLLocation, timestamp: Date)] = []

    /// Timer for elapsed time updates
    private var timer: Timer?

    /// Start time of current recording segment
    private var currentSegmentStartTime: Date?

    /// Accumulated moving time from previous segments
    private var accumulatedMovingTime: TimeInterval = 0.0

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(id: UUID = UUID(), type: ActivityType, startDate: Date = Date()) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.currentSegmentStartTime = startDate

        startTimer()
    }

    deinit {
        stopTimer()
    }

    // MARK: - Public Methods

    /// Add a new location sample and update metrics
    func addLocation(_ location: CLLocation) {
        // Create location sample
        let sample = LocationSample(location: location)
        locations.append(sample)
        metrics.locationCount = locations.count

        // Update distance
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            metrics.distance += distance
        }

        // Update elevation
        updateElevation(location.altitude)

        // Update current pace/speed
        updateCurrentPaceAndSpeed(location)

        // Update last location
        lastLocation = location
    }

    /// Start or resume the workout
    func start() {
        guard state != .recording else { return }

        state = .recording
        currentSegmentStartTime = Date()

        // Complete the last paused interval if any
        if var lastPause = pausedIntervals.last, lastPause.isActive {
            lastPause.complete()
            pausedIntervals[pausedIntervals.count - 1] = lastPause
        }

        startTimer()
    }

    /// Pause the workout
    func pause() {
        guard state == .recording else { return }

        state = .paused

        // Accumulate moving time from current segment
        if let segmentStart = currentSegmentStartTime {
            accumulatedMovingTime += Date().timeIntervalSince(segmentStart)
            currentSegmentStartTime = nil
        }

        // Create new paused interval
        let pauseInterval = PausedInterval(startTime: Date())
        pausedIntervals.append(pauseInterval)
    }

    /// Resume the workout after pause
    func resume() {
        start() // Reuse start logic
    }

    /// Stop the workout
    func stop() {
        state = .stopped

        // Accumulate final moving time
        if let segmentStart = currentSegmentStartTime {
            accumulatedMovingTime += Date().timeIntervalSince(segmentStart)
            currentSegmentStartTime = nil
        }

        // Complete any active pause
        if var lastPause = pausedIntervals.last, lastPause.isActive {
            lastPause.complete()
            pausedIntervals[pausedIntervals.count - 1] = lastPause
        }

        stopTimer()
    }

    /// Convert to completed Activity
    func toActivity() -> Activity {
        let endDate = Date()
        let totalDuration = endDate.timeIntervalSince(startDate)

        return Activity(
            id: id,
            type: type,
            startDate: startDate,
            endDate: endDate,
            distance: metrics.distance,
            duration: totalDuration,
            elevationGain: metrics.elevationGain,
            elevationLoss: metrics.elevationLoss,
            averagePace: metrics.averagePace,
            notes: nil,
            locations: locations,
            splits: splits
        )
    }

    // MARK: - Private Methods

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        metrics.elapsedTime = Date().timeIntervalSince(startDate)

        // Calculate moving time
        var movingTime = accumulatedMovingTime
        if let segmentStart = currentSegmentStartTime, state == .recording {
            movingTime += Date().timeIntervalSince(segmentStart)
        }
        metrics.movingTime = movingTime
    }

    private func updateElevation(_ altitude: Double) {
        guard let lastElev = lastElevation else {
            lastElevation = altitude
            return
        }

        // Filter out GPS noise - only count changes > 3 meters
        let elevationChange = altitude - lastElev
        if abs(elevationChange) > 3.0 {
            if elevationChange > 0 {
                metrics.elevationGain += elevationChange
            } else {
                metrics.elevationLoss += abs(elevationChange)
            }
            lastElevation = altitude
        }
    }

    private func updateCurrentPaceAndSpeed(_ location: CLLocation) {
        let now = Date()

        // Add to recent locations
        recentLocations.append((location: location, timestamp: now))

        // Keep only last 30 seconds of locations
        let thirtySecondsAgo = now.addingTimeInterval(-30)
        recentLocations.removeAll { $0.timestamp < thirtySecondsAgo }

        // Calculate current pace from recent locations
        if recentLocations.count >= 2 {
            let firstLoc = recentLocations.first!
            let lastLoc = recentLocations.last!

            let distance = lastLoc.location.distance(from: firstLoc.location)
            let time = lastLoc.timestamp.timeIntervalSince(firstLoc.timestamp)

            // Only calculate if we have meaningful distance (at least 20m)
            if distance >= 20 && time > 0 {
                let speed = distance / time
                metrics.currentSpeed = speed

                // Convert speed to pace (sec/km)
                if speed > 0.1 { // Avoid division by very small numbers
                    metrics.currentPace = 1000.0 / speed
                }
            }
        }

        // Use location's reported speed if available and valid
        if location.speed >= 0 {
            metrics.currentSpeed = location.speed
            if location.speed > 0.1 {
                metrics.currentPace = 1000.0 / location.speed
            }
        }
    }
}

// MARK: - Equatable

extension ActiveWorkout: Equatable {
    static func == (lhs: ActiveWorkout, rhs: ActiveWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

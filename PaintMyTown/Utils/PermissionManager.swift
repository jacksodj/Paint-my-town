//
//  PermissionManager.swift
//  PaintMyTown
//
//  Manages all app permissions including Location, Motion, and HealthKit
//  Implemented in M0 Phase 3 (Permissions Infrastructure)
//

import Foundation
import CoreLocation
import CoreMotion
import HealthKit
import Combine

/// Represents the current state of a permission
enum PermissionState: Equatable {
    case notDetermined
    case denied
    case authorized
    case restricted

    var isAuthorized: Bool {
        return self == .authorized
    }

    var canRequest: Bool {
        return self == .notDetermined
    }

    init(from status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        @unknown default:
            self = .notDetermined
        }
    }
}

/// Types of permissions used by the app
enum Permission: CaseIterable {
    case location
    case motion
    case healthKit

    var title: String {
        switch self {
        case .location:
            return "Location"
        case .motion:
            return "Motion & Fitness"
        case .healthKit:
            return "HealthKit"
        }
    }

    var icon: String {
        switch self {
        case .location:
            return "location.fill"
        case .motion:
            return "figure.walk"
        case .healthKit:
            return "heart.fill"
        }
    }
}

/// Protocol defining permission management capabilities
protocol PermissionManagerProtocol {
    var locationState: PermissionState { get }
    var motionState: PermissionState { get }
    var healthKitState: PermissionState { get }

    var locationStatePublisher: AnyPublisher<PermissionState, Never> { get }
    var motionStatePublisher: AnyPublisher<PermissionState, Never> { get }
    var healthKitStatePublisher: AnyPublisher<PermissionState, Never> { get }

    func checkLocationPermission() -> PermissionState
    func requestLocationPermission() async -> PermissionState

    func checkMotionPermission() -> PermissionState
    func requestMotionPermission() async -> PermissionState

    func checkHealthKitPermission() -> PermissionState
    func requestHealthKitPermission() async -> PermissionState

    func permissionRationale(for permission: Permission) -> String
    func permissionDescription(for permission: Permission) -> String

    func openSettings()
}

/// Manages all app permissions with state monitoring
class PermissionManager: NSObject, PermissionManagerProtocol, ObservableObject {

    // MARK: - Publishers

    private let locationStateSubject = CurrentValueSubject<PermissionState, Never>(.notDetermined)
    private let motionStateSubject = CurrentValueSubject<PermissionState, Never>(.notDetermined)
    private let healthKitStateSubject = CurrentValueSubject<PermissionState, Never>(.notDetermined)

    var locationStatePublisher: AnyPublisher<PermissionState, Never> {
        locationStateSubject.eraseToAnyPublisher()
    }

    var motionStatePublisher: AnyPublisher<PermissionState, Never> {
        motionStateSubject.eraseToAnyPublisher()
    }

    var healthKitStatePublisher: AnyPublisher<PermissionState, Never> {
        healthKitStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Published Properties

    @Published private(set) var locationState: PermissionState = .notDetermined
    @Published private(set) var motionState: PermissionState = .notDetermined
    @Published private(set) var healthKitState: PermissionState = .notDetermined

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private let healthStore = HKHealthStore()

    private var locationContinuation: CheckedContinuation<PermissionState, Never>?

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self

        // Initialize states
        updateLocationState()
        updateMotionState()
        updateHealthKitState()
    }

    // MARK: - Location Permission

    func checkLocationPermission() -> PermissionState {
        updateLocationState()
        return locationState
    }

    func requestLocationPermission() async -> PermissionState {
        // Check current authorization status
        let currentStatus = locationManager.authorizationStatus

        switch currentStatus {
        case .notDetermined:
            // Request when-in-use authorization first
            return await withCheckedContinuation { continuation in
                self.locationContinuation = continuation
                self.locationManager.requestWhenInUseAuthorization()
            }

        case .authorizedWhenInUse:
            // If we have when-in-use, request always
            return await withCheckedContinuation { continuation in
                self.locationContinuation = continuation
                self.locationManager.requestAlwaysAuthorization()
            }

        case .authorizedAlways:
            updateLocationState()
            return .authorized

        case .denied:
            updateLocationState()
            return .denied

        case .restricted:
            updateLocationState()
            return .restricted

        @unknown default:
            updateLocationState()
            return .denied
        }
    }

    private func updateLocationState() {
        let status = locationManager.authorizationStatus
        let state: PermissionState

        switch status {
        case .notDetermined:
            state = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            state = .authorized
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        @unknown default:
            state = .denied
        }

        locationState = state
        locationStateSubject.send(state)
    }

    // MARK: - Motion Permission

    func checkMotionPermission() -> PermissionState {
        updateMotionState()
        return motionState
    }

    func requestMotionPermission() async -> PermissionState {
        // Check if motion activity is available
        guard CMMotionActivityManager.isActivityAvailable() else {
            let state: PermissionState = .restricted
            motionState = state
            motionStateSubject.send(state)
            return state
        }

        // For iOS 11+, motion permission is requested automatically when querying
        return await withCheckedContinuation { continuation in
            let now = Date()

            // Query activity to trigger permission prompt
            motionActivityManager.queryActivityStarting(from: now, to: now, to: .main) { [weak self] activities, error in
                guard let self = self else {
                    continuation.resume(returning: .denied)
                    return
                }

                let state: PermissionState

                if let error = error as? CMError {
                    switch error.code {
                    case .motionActivityNotAuthorized:
                        state = .denied
                    case .motionActivityNotAvailable:
                        state = .restricted
                    default:
                        state = .denied
                    }
                } else {
                    // If no error, permission was granted
                    state = .authorized
                }

                self.motionState = state
                self.motionStateSubject.send(state)
                continuation.resume(returning: state)
            }
        }
    }

    private func updateMotionState() {
        // Motion permission state is difficult to check without triggering a prompt
        // We'll check if it's available and assume notDetermined if we haven't requested yet
        if !CMMotionActivityManager.isActivityAvailable() {
            let state: PermissionState = .restricted
            motionState = state
            motionStateSubject.send(state)
        }
        // Otherwise, state is maintained from last request
    }

    // MARK: - HealthKit Permission

    func checkHealthKitPermission() -> PermissionState {
        updateHealthKitState()
        return healthKitState
    }

    func requestHealthKitPermission() async -> PermissionState {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            let state: PermissionState = .restricted
            healthKitState = state
            healthKitStateSubject.send(state)
            return state
        }

        // Define the types we want to read and write
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

            // HealthKit doesn't tell us if permission was granted or denied
            // We'll check authorization status for a specific type
            let workoutType = HKObjectType.workoutType()
            let authStatus = healthStore.authorizationStatus(for: workoutType)

            let state: PermissionState
            switch authStatus {
            case .notDetermined:
                state = .notDetermined
            case .sharingAuthorized:
                state = .authorized
            case .sharingDenied:
                state = .denied
            @unknown default:
                state = .denied
            }

            healthKitState = state
            healthKitStateSubject.send(state)
            return state

        } catch {
            let state: PermissionState = .denied
            healthKitState = state
            healthKitStateSubject.send(state)
            return state
        }
    }

    private func updateHealthKitState() {
        guard HKHealthStore.isHealthDataAvailable() else {
            let state: PermissionState = .restricted
            healthKitState = state
            healthKitStateSubject.send(state)
            return
        }

        // Check authorization for workout type
        let workoutType = HKObjectType.workoutType()
        let authStatus = healthStore.authorizationStatus(for: workoutType)

        let state: PermissionState
        switch authStatus {
        case .notDetermined:
            state = .notDetermined
        case .sharingAuthorized:
            state = .authorized
        case .sharingDenied:
            state = .denied
        @unknown default:
            state = .denied
        }

        healthKitState = state
        healthKitStateSubject.send(state)
    }

    // MARK: - Permission Descriptions

    func permissionRationale(for permission: Permission) -> String {
        switch permission {
        case .location:
            return "Track your route and create a map of everywhere you've explored."

        case .motion:
            return "Automatically detect when you pause during workouts for more accurate activity tracking."

        case .healthKit:
            return "Save your workouts to the Health app and import your activity history."
        }
    }

    func permissionDescription(for permission: Permission) -> String {
        switch permission {
        case .location:
            return """
            Paint the Town needs access to your location to:

            • Track your route during workouts
            • Create coverage maps showing where you've been
            • Calculate distance and pace in real-time
            • Continue tracking even when the app is in the background

            Your location data is stored locally on your device and is never shared without your explicit consent.
            """

        case .motion:
            return """
            Paint the Town uses motion data to:

            • Detect when you stop moving during a workout
            • Automatically pause tracking when you take a break
            • Resume tracking when you start moving again
            • Improve accuracy of distance and pace calculations

            Motion data helps provide a better tracking experience without requiring you to manually pause.
            """

        case .healthKit:
            return """
            Paint the Town integrates with HealthKit to:

            • Save your workouts to the Health app
            • Sync workout data across your Apple devices
            • Import past workouts from other fitness apps
            • Include your full activity history in coverage maps

            HealthKit integration is optional. The app works fully without it, but your workouts won't be saved to Health.
            """
        }
    }

    // MARK: - Settings

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateLocationState()

        // Resume continuation if waiting
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: locationState)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // For iOS 13 and earlier
        updateLocationState()

        // Resume continuation if waiting
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: locationState)
        }
    }
}

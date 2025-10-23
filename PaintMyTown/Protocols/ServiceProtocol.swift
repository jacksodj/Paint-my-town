//
//  ServiceProtocol.swift
//  PaintMyTown
//
//  Created by Claude on 2025-10-23.
//

import Foundation
import Combine

/// Base protocol for all service implementations
/// Services contain business logic and coordinate between repositories and view models
protocol ServiceProtocol {
    /// Initialize the service
    /// Called when the service is first created
    func initialize() async throws

    /// Clean up resources when the service is being deallocated
    func cleanup()
}

/// Protocol for services that provide observable state
protocol ObservableServiceProtocol: ServiceProtocol {
    associatedtype State

    /// Publisher for state changes
    var statePublisher: AnyPublisher<State, Never> { get }

    /// Current state value
    var currentState: State { get }
}

/// Protocol for services that can be started and stopped
protocol LifecycleServiceProtocol: ServiceProtocol {
    /// Start the service
    func start() async throws

    /// Stop the service
    func stop() async throws

    /// Whether the service is currently running
    var isRunning: Bool { get }
}

/// Protocol for services that require authorization
protocol AuthorizableServiceProtocol: ServiceProtocol {
    /// Authorization state
    var isAuthorized: Bool { get }

    /// Request authorization from the user
    func requestAuthorization() async throws -> Bool

    /// Check current authorization status
    func checkAuthorization() async -> Bool
}

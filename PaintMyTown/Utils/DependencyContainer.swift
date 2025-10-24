//
//  DependencyContainer.swift
//  PaintMyTown
//
//  Created by Claude on 2025-10-23.
//

import Foundation

/// A simple dependency injection container for managing service and repository instances
/// This implementation uses a dictionary-based approach for flexibility and testability
final class DependencyContainer {
    // MARK: - Singleton

    /// Shared instance of the dependency container
    static let shared = DependencyContainer()

    // MARK: - Properties

    /// Storage for registered dependencies
    private var services: [String: Any] = [:]

    /// Lock for thread-safe access
    private let lock = NSLock()

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Register a service instance
    /// - Parameters:
    ///   - type: The protocol type to register
    ///   - instance: The concrete instance
    func register<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        services[key] = instance
    }

    /// Register a service factory
    /// - Parameters:
    ///   - type: The protocol type to register
    ///   - factory: A closure that creates the service instance
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        services[key] = factory()
    }

    /// Register a lazy service factory that creates the instance on first access
    /// - Parameters:
    ///   - type: The protocol type to register
    ///   - factory: A closure that creates the service instance
    func registerLazy<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        // Store the factory closure
        services[key] = LazyService(factory: factory)
    }

    // MARK: - Resolution

    /// Resolve a registered service
    /// - Parameter type: The protocol type to resolve
    /// - Returns: The registered instance
    func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)

        // Check if it's a lazy service
        if let lazyService = services[key] as? LazyService<T> {
            if lazyService.instance == nil {
                lazyService.instance = lazyService.factory()
            }
            guard let instance = lazyService.instance else {
                fatalError("Failed to create lazy instance for \(key)")
            }
            return instance
        }

        // Return the registered instance
        guard let service = services[key] as? T else {
            fatalError("Service \(key) not registered. Did you forget to register it in the container?")
        }

        return service
    }

    /// Optionally resolve a service (returns nil if not registered)
    /// - Parameter type: The protocol type to resolve
    /// - Returns: The registered instance or nil
    func resolveOptional<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)

        // Check if it's a lazy service
        if let lazyService = services[key] as? LazyService<T> {
            if lazyService.instance == nil {
                lazyService.instance = lazyService.factory()
            }
            return lazyService.instance
        }

        return services[key] as? T
    }

    // MARK: - Testing Support

    /// Unregister a service (useful for testing)
    /// - Parameter type: The protocol type to unregister
    func unregister<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        services.removeValue(forKey: key)
    }

    /// Unregister all services (useful for testing)
    func unregisterAll() {
        lock.lock()
        defer { lock.unlock() }

        services.removeAll()
    }

    /// Check if a service is registered
    /// - Parameter type: The protocol type to check
    /// - Returns: True if registered, false otherwise
    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        return services[key] != nil
    }
}

// MARK: - Lazy Service Wrapper

/// Internal wrapper for lazy service initialization
private class LazyService<T> {
    let factory: () -> T
    var instance: T?

    init(factory: @escaping () -> T) {
        self.factory = factory
    }
}

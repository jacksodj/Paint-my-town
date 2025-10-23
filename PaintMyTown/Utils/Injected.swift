//
//  Injected.swift
//  PaintMyTown
//
//  Created by Claude on 2025-10-23.
//

import Foundation

/// Property wrapper for automatic dependency injection
/// Usage:
/// ```
/// class MyViewModel {
///     @Injected var locationService: LocationServiceProtocol
/// }
/// ```
@propertyWrapper
struct Injected<T> {
    private var service: T?

    public init() {
        self.service = nil
    }

    public var wrappedValue: T {
        mutating get {
            if service == nil {
                service = DependencyContainer.shared.resolve(T.self)
            }
            return service!
        }
        mutating set {
            service = newValue
        }
    }

    /// Projected value provides direct access to the service
    public var projectedValue: T {
        mutating get {
            return wrappedValue
        }
    }
}

/// Property wrapper for optional dependency injection
/// Returns nil if the dependency is not registered
@propertyWrapper
struct InjectedOptional<T> {
    private var service: T?

    public init() {
        self.service = nil
    }

    public var wrappedValue: T? {
        mutating get {
            if service == nil {
                service = DependencyContainer.shared.resolveOptional(T.self)
            }
            return service
        }
        mutating set {
            service = newValue
        }
    }
}

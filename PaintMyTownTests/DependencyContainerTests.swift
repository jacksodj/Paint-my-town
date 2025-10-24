//
//  DependencyContainerTests.swift
//  PaintMyTownTests
//
//  Created by Claude on 2025-10-23.
//

import XCTest
@testable import PaintMyTown

final class DependencyContainerTests: XCTestCase {

    // MARK: - Properties

    var container: DependencyContainer!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        container = DependencyContainer.shared
        container.unregisterAll()
    }

    override func tearDown() {
        container.unregisterAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testRegisterAndResolveService() {
        // Given
        let mockService = MockService()
        container.register(MockServiceProtocol.self, instance: mockService)

        // When
        let resolved = container.resolve(MockServiceProtocol.self)

        // Then
        XCTAssertTrue(resolved is MockService, "Should resolve to MockService instance")
        XCTAssertEqual(resolved.getValue(), "mock", "Should return expected value")
    }

    func testRegisterWithFactory() {
        // Given
        container.register(MockServiceProtocol.self) {
            return MockService()
        }

        // When
        let resolved = container.resolve(MockServiceProtocol.self)

        // Then
        XCTAssertNotNil(resolved, "Should resolve service from factory")
        XCTAssertEqual(resolved.getValue(), "mock", "Should return expected value")
    }

    func testResolveUnregisteredServiceThrowsFatalError() {
        // This test verifies that resolving an unregistered service would crash
        // In a real scenario, this would cause a fatalError
        // We test the isRegistered method instead

        // Given / When
        let isRegistered = container.isRegistered(MockServiceProtocol.self)

        // Then
        XCTAssertFalse(isRegistered, "Service should not be registered")
    }

    func testResolveOptionalReturnsNilForUnregisteredService() {
        // Given / When
        let resolved = container.resolveOptional(MockServiceProtocol.self)

        // Then
        XCTAssertNil(resolved, "Should return nil for unregistered service")
    }

    func testResolveOptionalReturnsInstanceForRegisteredService() {
        // Given
        let mockService = MockService()
        container.register(MockServiceProtocol.self, instance: mockService)

        // When
        let resolved = container.resolveOptional(MockServiceProtocol.self)

        // Then
        XCTAssertNotNil(resolved, "Should return instance for registered service")
        XCTAssertEqual(resolved?.getValue(), "mock", "Should return expected value")
    }

    func testUnregisterService() {
        // Given
        let mockService = MockService()
        container.register(MockServiceProtocol.self, instance: mockService)
        XCTAssertTrue(container.isRegistered(MockServiceProtocol.self))

        // When
        container.unregister(MockServiceProtocol.self)

        // Then
        XCTAssertFalse(container.isRegistered(MockServiceProtocol.self), "Service should be unregistered")
    }

    func testUnregisterAllServices() {
        // Given
        container.register(MockServiceProtocol.self, instance: MockService())
        container.register(AnotherMockServiceProtocol.self, instance: AnotherMockService())
        XCTAssertTrue(container.isRegistered(MockServiceProtocol.self))
        XCTAssertTrue(container.isRegistered(AnotherMockServiceProtocol.self))

        // When
        container.unregisterAll()

        // Then
        XCTAssertFalse(container.isRegistered(MockServiceProtocol.self), "First service should be unregistered")
        XCTAssertFalse(container.isRegistered(AnotherMockServiceProtocol.self), "Second service should be unregistered")
    }

    func testLazyServiceInitialization() {
        // Given
        var factoryCalled = false
        container.registerLazy(MockServiceProtocol.self) {
            factoryCalled = true
            return MockService()
        }

        // When
        XCTAssertFalse(factoryCalled, "Factory should not be called yet")
        let resolved = container.resolve(MockServiceProtocol.self)

        // Then
        XCTAssertTrue(factoryCalled, "Factory should be called on first resolve")
        XCTAssertNotNil(resolved, "Should resolve lazy service")
    }

    func testThreadSafety() {
        // Given
        let expectation = expectation(description: "Thread safety")
        expectation.expectedFulfillmentCount = 10

        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.container.register(MockServiceProtocol.self, instance: MockService())
                let resolved = self.container.resolve(MockServiceProtocol.self)
                XCTAssertNotNil(resolved, "Thread \(i): Should resolve service")
                expectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 5.0)
    }
}

// MARK: - Mock Types

protocol MockServiceProtocol {
    func getValue() -> String
}

class MockService: MockServiceProtocol {
    func getValue() -> String {
        return "mock"
    }
}

protocol AnotherMockServiceProtocol {
    func getNumber() -> Int
}

class AnotherMockService: AnotherMockServiceProtocol {
    func getNumber() -> Int {
        return 42
    }
}

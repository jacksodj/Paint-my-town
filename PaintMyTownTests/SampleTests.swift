//
//  SampleTests.swift
//  PaintMyTownTests
//
//  Created by Claude on 2025-10-23.
//

import XCTest
@testable import PaintMyTown

/// Sample test file demonstrating the test setup
/// This serves as a template for future test files
final class SampleTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before each test method.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after each test method.
        try super.tearDownWithError()
    }

    // MARK: - Sample Tests

    func testExample() throws {
        // Given
        let expectedValue = 42

        // When
        let actualValue = 42

        // Then
        XCTAssertEqual(actualValue, expectedValue, "Values should be equal")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
            _ = (0..<1000).map { $0 * 2 }
        }
    }

    // MARK: - Async Tests

    func testAsyncExample() async throws {
        // Example of testing async code
        let result = await fetchSampleData()
        XCTAssertEqual(result, "sample", "Async result should match expected value")
    }

    // MARK: - Helper Methods

    private func fetchSampleData() async -> String {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return "sample"
    }
}

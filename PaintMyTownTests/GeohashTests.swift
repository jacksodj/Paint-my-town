//
//  GeohashTests.swift
//  PaintMyTownTests
//
//  Tests for geohash encoding and decoding
//

import XCTest
import CoreLocation
@testable import PaintMyTown

final class GeohashTests: XCTestCase {

    // MARK: - Encoding Tests

    func testEncodeCoordinate() {
        // Test San Francisco coordinates
        let lat = 37.7749
        let lon = -122.4194
        let precision = 7

        let geohash = Geohash.encode(latitude: lat, longitude: lon, precision: precision)

        XCTAssertEqual(geohash.count, precision)
        XCTAssertFalse(geohash.isEmpty)
    }

    func testEncodeKnownLocation() {
        // Test known geohash for London (51.5074, -0.1278)
        let geohash = Geohash.encode(latitude: 51.5074, longitude: -0.1278, precision: 5)
        XCTAssertEqual(geohash, "gcpvj")
    }

    func testEncodeDifferentPrecisions() {
        let lat = 37.7749
        let lon = -122.4194

        let geohash5 = Geohash.encode(latitude: lat, longitude: lon, precision: 5)
        let geohash7 = Geohash.encode(latitude: lat, longitude: lon, precision: 7)
        let geohash9 = Geohash.encode(latitude: lat, longitude: lon, precision: 9)

        XCTAssertEqual(geohash5.count, 5)
        XCTAssertEqual(geohash7.count, 7)
        XCTAssertEqual(geohash9.count, 9)

        // Longer precision should start with shorter precision
        XCTAssertTrue(geohash7.hasPrefix(geohash5))
        XCTAssertTrue(geohash9.hasPrefix(geohash7))
    }

    // MARK: - Decoding Tests

    func testDecodeGeohash() {
        let geohash = "9q8yy"
        let box = Geohash.decode(geohash)

        // Should be near San Francisco
        XCTAssertGreaterThan(box.center.latitude, 37.0)
        XCTAssertLessThan(box.center.latitude, 38.0)
        XCTAssertGreaterThan(box.center.longitude, -123.0)
        XCTAssertLessThan(box.center.longitude, -122.0)
    }

    func testEncodeDecodeRoundtrip() {
        let originalLat = 37.7749
        let originalLon = -122.4194

        let geohash = Geohash.encode(latitude: originalLat, longitude: originalLon, precision: 7)
        let box = Geohash.decode(geohash)

        // Decoded center should be close to original coordinates
        // (within the precision tolerance of ~76m for precision 7)
        let latDiff = abs(box.center.latitude - originalLat)
        let lonDiff = abs(box.center.longitude - originalLon)

        XCTAssertLessThan(latDiff, 0.001) // ~111m
        XCTAssertLessThan(lonDiff, 0.001)
    }

    // MARK: - Neighbor Tests

    func testNeighborRight() {
        let geohash = "9q8yy"
        let right = Geohash.neighbor(geohash, direction: "right")

        XCTAssertNotEqual(right, geohash)
        XCTAssertEqual(right.count, geohash.count)
    }

    func testNeighborLeft() {
        let geohash = "9q8yy"
        let left = Geohash.neighbor(geohash, direction: "left")

        XCTAssertNotEqual(left, geohash)
        XCTAssertEqual(left.count, geohash.count)
    }

    func testAllNeighbors() {
        let geohash = "9q8yy"
        let neighborList = Geohash.neighbors(geohash)

        XCTAssertEqual(neighborList.count, 8)

        // All neighbors should have same precision
        for neighbor in neighborList {
            XCTAssertEqual(neighbor.count, geohash.count)
        }

        // All neighbors should be different
        let uniqueNeighbors = Set(neighborList)
        XCTAssertEqual(uniqueNeighbors.count, 8)

        // None should be the original geohash
        XCTAssertFalse(neighborList.contains(geohash))
    }

    // MARK: - Bounding Box Tests

    func testGeohashesInBoundingBox() {
        let minLat = 37.7
        let maxLat = 37.8
        let minLon = -122.5
        let maxLon = -122.4

        let geohashes = Geohash.geohashesInBoundingBox(
            minLatitude: minLat,
            maxLatitude: maxLat,
            minLongitude: minLon,
            maxLongitude: maxLon,
            precision: 6
        )

        XCTAssertGreaterThan(geohashes.count, 0)

        // All geohashes should be within or near the bounding box
        for geohash in geohashes {
            let box = Geohash.decode(geohash)
            XCTAssertGreaterThan(box.center.latitude, minLat - 0.1)
            XCTAssertLessThan(box.center.latitude, maxLat + 0.1)
        }
    }

    // MARK: - Precision Tests

    func testPrecisionForZoomLevel() {
        XCTAssertEqual(Geohash.precisionForZoomLevel(1), 2)
        XCTAssertEqual(Geohash.precisionForZoomLevel(5), 3)
        XCTAssertEqual(Geohash.precisionForZoomLevel(10), 5)
        XCTAssertEqual(Geohash.precisionForZoomLevel(15), 7)
        XCTAssertEqual(Geohash.precisionForZoomLevel(20), 9)
    }

    func testDimensionsForPrecision() {
        let dims7 = Geohash.dimensionsForPrecision(7)
        XCTAssertEqual(dims7.width, 153, accuracy: 1)
        XCTAssertEqual(dims7.height, 153, accuracy: 1)

        let dims5 = Geohash.dimensionsForPrecision(5)
        XCTAssertGreaterThan(dims5.width, dims7.width)
        XCTAssertGreaterThan(dims5.height, dims7.height)
    }

    // MARK: - Edge Cases

    func testEncodeEquator() {
        let geohash = Geohash.encode(latitude: 0, longitude: 0, precision: 7)
        let box = Geohash.decode(geohash)

        XCTAssertEqual(box.center.latitude, 0, accuracy: 0.01)
        XCTAssertEqual(box.center.longitude, 0, accuracy: 0.01)
    }

    func testEncodeNorthPole() {
        let geohash = Geohash.encode(latitude: 89.9, longitude: 0, precision: 7)
        let box = Geohash.decode(geohash)

        XCTAssertGreaterThan(box.center.latitude, 89.0)
    }

    func testEncodeSouthPole() {
        let geohash = Geohash.encode(latitude: -89.9, longitude: 0, precision: 7)
        let box = Geohash.decode(geohash)

        XCTAssertLessThan(box.center.latitude, -89.0)
    }

    func testEncodeInternationalDateLine() {
        let geohashWest = Geohash.encode(latitude: 0, longitude: 179.9, precision: 7)
        let geohashEast = Geohash.encode(latitude: 0, longitude: -179.9, precision: 7)

        XCTAssertNotEqual(geohashWest, geohashEast)
    }
}

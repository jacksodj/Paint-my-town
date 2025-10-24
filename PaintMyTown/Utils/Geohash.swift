//
//  Geohash.swift
//  PaintMyTown
//
//  Geohash encoding/decoding for coverage tile generation
//

import Foundation
import CoreLocation

/// Geohash utility for encoding and decoding geographic coordinates
struct Geohash {

    // MARK: - Constants

    /// Base32 characters used in geohash encoding
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    /// Map of geohash neighbor offsets for each direction and odd/even state
    private static let neighbors: [String: [String]] = [
        "right": ["even": "bc01fg45238967deuvhjyznpkmstqrwx", "odd": "p0r21436x8zb9dcf5h7kjnmqesgutwvy"],
        "left": ["even": "238967debc01fg45kmstqrwxuvhjyznp", "odd": "14365h7k9dcfesgujnmqp0r2twvyx8zb"],
        "top": ["even": "p0r21436x8zb9dcf5h7kjnmqesgutwvy", "odd": "bc01fg45238967deuvhjyznpkmstqrwx"],
        "bottom": ["even": "14365h7k9dcfesgujnmqp0r2twvyx8zb", "odd": "238967debc01fg45kmstqrwxuvhjyznp"]
    ]

    /// Border characters for each direction and odd/even state
    private static let borders: [String: [String]] = [
        "right": ["even": "bcfguvyz", "odd": "prxz"],
        "left": ["even": "0145hjnp", "odd": "028b"],
        "top": ["even": "prxz", "odd": "bcfguvyz"],
        "bottom": ["even": "028b", "odd": "0145hjnp"]
    ]

    // MARK: - Encoding

    /// Encode a coordinate into a geohash string
    /// - Parameters:
    ///   - latitude: Latitude (-90 to 90)
    ///   - longitude: Longitude (-180 to 180)
    ///   - precision: Number of characters in the resulting geohash (1-12)
    /// - Returns: Geohash string
    static func encode(latitude: Double, longitude: Double, precision: Int = 7) -> String {
        var geohash = ""
        var bits = 0
        var bit = 0
        var even = true

        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)

        while geohash.count < precision {
            if even {
                // Longitude
                let mid = (lonRange.0 + lonRange.1) / 2
                if longitude > mid {
                    bit |= (1 << (4 - bits))
                    lonRange.0 = mid
                } else {
                    lonRange.1 = mid
                }
            } else {
                // Latitude
                let mid = (latRange.0 + latRange.1) / 2
                if latitude > mid {
                    bit |= (1 << (4 - bits))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }

            even = !even
            bits += 1

            if bits == 5 {
                geohash.append(base32[bit])
                bits = 0
                bit = 0
            }
        }

        return geohash
    }

    /// Encode a CLLocationCoordinate2D into a geohash string
    /// - Parameters:
    ///   - coordinate: The coordinate to encode
    ///   - precision: Number of characters in the resulting geohash (1-12)
    /// - Returns: Geohash string
    static func encode(coordinate: CLLocationCoordinate2D, precision: Int = 7) -> String {
        encode(latitude: coordinate.latitude, longitude: coordinate.longitude, precision: precision)
    }

    // MARK: - Decoding

    /// Bounding box for a decoded geohash
    struct BoundingBox {
        let minLatitude: Double
        let maxLatitude: Double
        let minLongitude: Double
        let maxLongitude: Double

        var center: CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            )
        }

        var latitudeHeight: Double {
            maxLatitude - minLatitude
        }

        var longitudeWidth: Double {
            maxLongitude - minLongitude
        }
    }

    /// Decode a geohash string into a bounding box
    /// - Parameter geohash: The geohash string to decode
    /// - Returns: BoundingBox containing the area represented by the geohash
    static func decode(_ geohash: String) -> BoundingBox {
        var bits = 0
        var even = true

        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)

        for char in geohash.lowercased() {
            guard let index = base32.firstIndex(of: char) else {
                continue
            }

            let byte = base32.distance(from: base32.startIndex, to: index)

            for i in (0..<5).reversed() {
                let bit = (byte >> i) & 1

                if even {
                    // Longitude
                    let mid = (lonRange.0 + lonRange.1) / 2
                    if bit == 1 {
                        lonRange.0 = mid
                    } else {
                        lonRange.1 = mid
                    }
                } else {
                    // Latitude
                    let mid = (latRange.0 + latRange.1) / 2
                    if bit == 1 {
                        latRange.0 = mid
                    } else {
                        latRange.1 = mid
                    }
                }

                even = !even
            }
        }

        return BoundingBox(
            minLatitude: latRange.0,
            maxLatitude: latRange.1,
            minLongitude: lonRange.0,
            maxLongitude: lonRange.1
        )
    }

    // MARK: - Neighbors

    /// Get the neighboring geohash in a specific direction
    /// - Parameters:
    ///   - geohash: The source geohash
    ///   - direction: The direction (right, left, top, bottom)
    /// - Returns: The neighboring geohash string
    static func neighbor(_ geohash: String, direction: String) -> String {
        guard !geohash.isEmpty else { return "" }

        let lastChar = String(geohash.last!)
        let type = geohash.count % 2 == 0 ? "even" : "odd"
        var base = String(geohash.dropLast())

        // Check if we're at a border
        if let border = borders[direction]?[type], border.contains(lastChar) {
            base = neighbor(base, direction: direction)
        }

        // Look up the neighbor character
        guard let neighborChars = neighbors[direction]?[type],
              let charIndex = base32.firstIndex(of: Character(lastChar)),
              let neighborChar = neighborChars[safe: base32.distance(from: base32.startIndex, to: charIndex)] else {
            return geohash
        }

        return base + String(neighborChar)
    }

    /// Get all 8 neighboring geohashes
    /// - Parameter geohash: The source geohash
    /// - Returns: Array of 8 neighboring geohashes [top, topRight, right, bottomRight, bottom, bottomLeft, left, topLeft]
    static func neighbors(_ geohash: String) -> [String] {
        let top = neighbor(geohash, direction: "top")
        let bottom = neighbor(geohash, direction: "bottom")
        let right = neighbor(geohash, direction: "right")
        let left = neighbor(geohash, direction: "left")

        return [
            top,
            neighbor(top, direction: "right"),  // top-right
            right,
            neighbor(bottom, direction: "right"),  // bottom-right
            bottom,
            neighbor(bottom, direction: "left"),  // bottom-left
            left,
            neighbor(top, direction: "left")  // top-left
        ]
    }

    // MARK: - Bounding Box Operations

    /// Generate all geohashes that cover a given bounding box
    /// - Parameters:
    ///   - minLatitude: Minimum latitude
    ///   - maxLatitude: Maximum latitude
    ///   - minLongitude: Minimum longitude
    ///   - maxLongitude: Maximum longitude
    ///   - precision: Geohash precision level
    /// - Returns: Set of geohash strings covering the area
    static func geohashesInBoundingBox(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        precision: Int = 7
    ) -> Set<String> {
        var geohashes = Set<String>()

        // Calculate the approximate number of geohashes needed
        let centerLat = (minLatitude + maxLatitude) / 2
        let centerLon = (minLongitude + maxLongitude) / 2

        // Start with center geohash
        let centerGeohash = encode(latitude: centerLat, longitude: centerLon, precision: precision)
        let box = decode(centerGeohash)

        // Calculate how many tiles we need in each direction
        let latSteps = max(1, Int(ceil((maxLatitude - minLatitude) / box.latitudeHeight)))
        let lonSteps = max(1, Int(ceil((maxLongitude - minLongitude) / box.longitudeWidth)))

        // Generate grid of geohashes
        let latStep = (maxLatitude - minLatitude) / Double(latSteps)
        let lonStep = (maxLongitude - minLongitude) / Double(lonSteps)

        for i in 0..<latSteps {
            for j in 0..<lonSteps {
                let lat = minLatitude + (Double(i) + 0.5) * latStep
                let lon = minLongitude + (Double(j) + 0.5) * lonStep
                let hash = encode(latitude: lat, longitude: lon, precision: precision)
                geohashes.insert(hash)
            }
        }

        return geohashes
    }

    // MARK: - Precision Helpers

    /// Get the appropriate geohash precision for a given zoom level
    /// - Parameter zoomLevel: Map zoom level (typically 0-20)
    /// - Returns: Recommended geohash precision (1-12)
    static func precisionForZoomLevel(_ zoomLevel: Double) -> Int {
        switch zoomLevel {
        case ..<3:  return 2   // World view
        case 3..<6: return 3   // Continent
        case 6..<9: return 4   // Country
        case 9..<12: return 5  // Region
        case 12..<14: return 6 // City
        case 14..<16: return 7 // District
        case 16..<18: return 8 // Street
        case 18...: return 9   // Building
        default: return 7
        }
    }

    /// Get the approximate dimensions of a geohash cell
    /// - Parameter precision: Geohash precision level
    /// - Returns: Approximate width and height in meters
    static func dimensionsForPrecision(_ precision: Int) -> (width: Double, height: Double) {
        switch precision {
        case 1: return (5000000, 5000000)    // ±2500km
        case 2: return (1250000, 625000)     // ±625km × 313km
        case 3: return (156000, 156000)      // ±78km
        case 4: return (39100, 19500)        // ±19.5km × 9.8km
        case 5: return (4900, 4900)          // ±2.4km
        case 6: return (1200, 609)           // ±600m × 305m
        case 7: return (153, 153)            // ±76m (good for coverage tiles)
        case 8: return (38, 19)              // ±19m × 9.5m
        case 9: return (4.8, 4.8)            // ±2.4m
        case 10: return (1.2, 0.6)           // ±60cm × 30cm
        case 11: return (0.15, 0.15)         // ±7.5cm
        case 12: return (0.037, 0.019)       // ±1.9cm × 0.95cm
        default: return (153, 153)           // Default to precision 7
        }
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - String Extension

private extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

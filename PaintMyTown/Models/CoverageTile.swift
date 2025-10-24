//
//  CoverageTile.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreLocation

/// Domain model representing a geographical coverage tile
struct CoverageTile: Identifiable, Codable {
    let id: String // Using geohash as ID
    let geohash: String
    let latitude: Double
    let longitude: Double
    let visitCount: Int
    let firstVisited: Date
    let lastVisited: Date

    init(
        geohash: String,
        latitude: Double,
        longitude: Double,
        visitCount: Int,
        firstVisited: Date,
        lastVisited: Date
    ) {
        self.id = geohash
        self.geohash = geohash
        self.latitude = latitude
        self.longitude = longitude
        self.visitCount = visitCount
        self.firstVisited = firstVisited
        self.lastVisited = lastVisited
    }

    /// Center coordinate of the tile
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

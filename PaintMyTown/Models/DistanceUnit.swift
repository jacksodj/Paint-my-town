//
//  DistanceUnit.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation

/// Represents the unit of distance measurement
enum DistanceUnit: String, CaseIterable, Codable {
    case kilometers = "km"
    case miles = "mi"

    var displayName: String {
        switch self {
        case .kilometers:
            return "Kilometers"
        case .miles:
            return "Miles"
        }
    }

    var abbreviation: String {
        return rawValue
    }
}

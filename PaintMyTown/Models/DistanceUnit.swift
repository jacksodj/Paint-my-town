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

    var shortName: String {
        return rawValue
    }

    var name: String {
        switch self {
        case .kilometers:
            return "kilometer"
        case .miles:
            return "mile"
        }
    }

    var metersPerUnit: Double {
        switch self {
        case .kilometers:
            return 1000.0
        case .miles:
            return 1609.344
        }
    }
}

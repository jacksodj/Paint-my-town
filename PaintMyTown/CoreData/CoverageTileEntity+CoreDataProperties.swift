//
//  CoverageTileEntity+CoreDataProperties.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

extension CoverageTileEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoverageTileEntity> {
        return NSFetchRequest<CoverageTileEntity>(entityName: "CoverageTileEntity")
    }

    @NSManaged public var geohash: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var visitCount: Int32
    @NSManaged public var firstVisited: Date
    @NSManaged public var lastVisited: Date
}

extension CoverageTileEntity: Identifiable {
    public var id: String {
        return geohash
    }
}

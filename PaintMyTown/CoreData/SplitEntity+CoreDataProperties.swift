//
//  SplitEntity+CoreDataProperties.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

extension SplitEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SplitEntity> {
        return NSFetchRequest<SplitEntity>(entityName: "SplitEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var distance: Double
    @NSManaged public var duration: Double
    @NSManaged public var pace: Double
    @NSManaged public var elevationGain: Double
    @NSManaged public var activity: ActivityEntity?
}

extension SplitEntity: Identifiable {
}

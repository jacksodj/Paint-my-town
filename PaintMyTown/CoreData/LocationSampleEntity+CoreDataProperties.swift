//
//  LocationSampleEntity+CoreDataProperties.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import CoreData

extension LocationSampleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationSampleEntity> {
        return NSFetchRequest<LocationSampleEntity>(entityName: "LocationSampleEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var altitude: Double
    @NSManaged public var horizontalAccuracy: Double
    @NSManaged public var verticalAccuracy: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var speed: Double
    @NSManaged public var activity: ActivityEntity?
}

extension LocationSampleEntity: Identifiable {
}

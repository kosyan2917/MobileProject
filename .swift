//
//  Tracks+CoreDataProperties.swift
//  MobileProject
//
//  Created by Никита Косянков on 06.04.2025.
//
//

import Foundation
import CoreData


extension Tracks {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tracks> {
        return NSFetchRequest<Tracks>(entityName: "Tracks")
    }

    @NSManaged public var name: String?
    @NSManaged public var isPublished: Bool
    @NSManaged public var createdAt: Date?

}

extension Tracks : Identifiable {

}

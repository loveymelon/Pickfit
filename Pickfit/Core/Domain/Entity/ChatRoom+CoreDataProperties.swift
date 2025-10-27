//
//  ChatRoom+CoreDataProperties.swift
//  Pickfit
//
//  Created by 김진수 on 10/21/25.
//

import Foundation
import CoreData

extension ChatRoom {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatRoom> {
        return NSFetchRequest<ChatRoom>(entityName: "ChatRoom")
    }

    @NSManaged public var roomId: String?
    @NSManaged public var lastReadChatId: String?
    @NSManaged public var updatedAt: String?

    // Relationship
    @NSManaged public var messages: NSSet?

}

// MARK: Generated accessors for messages
extension ChatRoom {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

extension ChatRoom : Identifiable {

}

//
//  ChatMessageMO+CoreDataProperties.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import Foundation
import CoreData

extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var chatId: String?
    @NSManaged public var roomId: String?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: String?
    @NSManaged public var updatedAt: String?
    @NSManaged public var senderId: String?
    @NSManaged public var senderNick: String?
    @NSManaged public var senderProfileImage: String?
    @NSManaged public var filesJSON: String?
    @NSManaged public var isMyMessage: Bool

}

extension Message : Identifiable {

}

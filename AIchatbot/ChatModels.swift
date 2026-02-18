//
//  ChatModels.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var text: String
    var isUser: Bool
    var timestamp: Date
    @Attribute(.externalStorage) var imageData: Data?
    var isThinking: Bool
    
    var session: ChatSession?
    
    init(text: String, isUser: Bool, imageData: Data? = nil, isThinking: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.imageData = imageData
        self.isThinking = isThinking
    }
}

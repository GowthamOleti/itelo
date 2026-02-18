//
//  SiriSuggestionsService.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation
import Intents
import CoreSpotlight
import SwiftData

@available(iOS 26.0, *)
class SiriSuggestionsService {
    static let shared = SiriSuggestionsService()
    private var modelContext: ModelContext?

    private init() {}

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Siri Proactive Suggestions
    func donateChatIntent(with prompt: String, sessionId: UUID?) {
        let intent = StartChatIntent()
        intent.prompt = prompt
        intent.sessionId = sessionId?.uuidString

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Error donating chat intent: \(error)")
            }
        }
    }

    func donateQuickReplyIntent(reply: String) {
        let intent = QuickReplyIntent()
        intent.reply = reply

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Error donating quick reply intent: \(error)")
            }
        }
    }

    // MARK: - Spotlight Integration
    func indexChatSession(_ session: ChatSession) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = session.title
        attributeSet.contentDescription = session.messages.first?.text ?? "Chat conversation"
        attributeSet.keywords = ["chat", "conversation", "AI", "assistant"]

        // Add recent message preview
        if let lastMessage = session.messages.sorted(by: { $0.timestamp > $1.timestamp }).first {
            attributeSet.contentDescription = lastMessage.text
        }

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: "chat_\(session.id)",
            domainIdentifier: "com.ai.chatbot.conversations",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Error indexing chat session: \(error)")
            }
        }
    }

    func removeFromIndex(_ session: ChatSession) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["chat_\(session.id)"]) { error in
            if let error = error {
                print("Error removing chat from index: \(error)")
            }
        }
    }

    // MARK: - Contextual Suggestions
    func suggestBasedOnContext() {
        // Suggest common conversation starters
        let suggestions = [
            "Help me plan my day",
            "What's the weather like?",
            "Set a reminder for me",
            "Tell me a joke",
            "What's new with AI?"
        ]

        for suggestion in suggestions {
            donateQuickReplyIntent(reply: suggestion)
        }

        // Suggest based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let timeBasedSuggestions: [String]

        switch hour {
        case 6..<12:
            timeBasedSuggestions = ["Good morning! What's on your agenda?", "Plan my morning routine"]
        case 12..<17:
            timeBasedSuggestions = ["What's for lunch?", "Any afternoon meetings?"]
        case 17..<22:
            timeBasedSuggestions = ["Evening plans?", "What's for dinner?"]
        default:
            timeBasedSuggestions = ["Good night!", "Set alarm for tomorrow"]
        }

        for suggestion in timeBasedSuggestions {
            donateQuickReplyIntent(reply: suggestion)
        }
    }

    // MARK: - Predictive Suggestions
    func suggestBasedOnHistory() {
        guard let context = modelContext else { return }

        do {
            let sessions = try context.fetch(FetchDescriptor<ChatSession>())
            let allMessages = sessions.flatMap { $0.messages }

            // Analyze common topics/themes
            let userMessages = allMessages.filter { $0.isUser }
            let topics = extractTopics(from: userMessages.map { $0.text })

            // Generate topic-based suggestions
            for topic in topics.prefix(5) {
                let suggestion = "Tell me more about \(topic)"
                donateQuickReplyIntent(reply: suggestion)
            }

        } catch {
            print("Error fetching chat history for suggestions: \(error)")
        }
    }

    private func extractTopics(from messages: [String]) -> [String] {
        // Simple topic extraction - in a real implementation, this would use NLP
        let commonTopics = [
            "weather", "food", "work", "travel", "music", "movies",
            "sports", "health", "technology", "coding", "design"
        ]

        var topicCounts: [String: Int] = [:]

        for message in messages {
            let lowerMessage = message.lowercased()
            for topic in commonTopics {
                if lowerMessage.contains(topic) {
                    topicCounts[topic, default: 0] += 1
                }
            }
        }

        return topicCounts.sorted { $0.value > $1.value }.map { $0.key }
    }

    // MARK: - Shortcut Suggestions
    func createShortcuts() {
        // Create Siri shortcuts for common actions
        let commonActions = [
            ("Start New Chat", "startChat"),
            ("Quick Reminder", "createReminder"),
            ("Set Alarm", "setAlarm"),
            ("Generate Image", "generateImage")
        ]

        for (title, action) in commonActions {
            let intent = INShortcut(intent: createIntent(for: action))
        }
    }

    private func createIntent(for action: String) -> INIntent {
        switch action {
        case "startChat":
            let intent = StartChatIntent()
            intent.prompt = "Hello!"
            return intent
        case "createReminder":
            let intent = CreateReminderIntent()
            intent.title = "Quick reminder"
            return intent
        case "setAlarm":
            let intent = SetAlarmIntent()
            return intent
        case "generateImage":
            let intent = GenerateImageIntent()
            intent.prompt = "A beautiful landscape"
            return intent
        default:
            return StartChatIntent()
        }
    }
}

// MARK: - Custom Intents
@available(iOS 26.0, *)
class StartChatIntent: INIntent {
    @NSManaged var prompt: String?
    @NSManaged var sessionId: String?
}

@available(iOS 26.0, *)
class QuickReplyIntent: INIntent {
    @NSManaged var reply: String?
}

@available(iOS 26.0, *)
class CreateReminderIntent: INIntent {
    @NSManaged var title: String?
    @NSManaged var dueDate: Date?
}

@available(iOS 26.0, *)
class SetAlarmIntent: INIntent {
    @NSManaged var time: Date?
    @NSManaged var label: String?
}

@available(iOS 26.0, *)
class GenerateImageIntent: INIntent {
    @NSManaged var prompt: String?
}

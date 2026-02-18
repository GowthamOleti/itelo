//
//  AISearchService.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation
import FoundationModels
import SwiftData
import NaturalLanguage

@available(iOS 26.0, *)
class AISearchService {
    static let shared = AISearchService()
    private let languageModel: SystemLanguageModel
    private var modelContext: ModelContext?

    private init() {
        // Initialize with the most advanced available model
        self.languageModel = SystemLanguageModel.default
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Conversation Summarization
    func summarizeConversation(_ session: ChatSession) async throws -> String {
        let messages = session.messages.sorted { $0.timestamp < $1.timestamp }
        let conversationText = messages.map { $0.isUser ? "User: \($0.text)" : "AI: \($0.text)" }.joined(separator: "\n")

        let prompt = """
        Summarize this conversation in 2-3 sentences, capturing the main topics discussed and any key decisions or outcomes:

        \(conversationText)

        Summary:
        """

        let session = try await LanguageModelSession(model: languageModel)
        let response = try await session.respond(to: prompt)

        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateTitle(for session: ChatSession) async throws -> String {
        let messages = session.messages.sorted { $0.timestamp < $1.timestamp }
        let firstFewMessages = messages.prefix(3).map { $0.text }.joined(separator: " ")

        let prompt = """
        Generate a concise, descriptive title (max 6 words) for this conversation based on the beginning:

        \(firstFewMessages)

        Title:
        """

        let languageSession = try await LanguageModelSession(model: languageModel)
        let response = try await languageSession.respond(to: prompt)

        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Semantic Search
    func searchConversations(query: String, limit: Int = 10) async throws -> [ChatSession] {
        guard let context = modelContext else { throw NSError(domain: "AISearch", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context"]) }

        let sessions = try context.fetch(FetchDescriptor<ChatSession>())

        // Use natural language processing for semantic search
        let queryEmbedding = try await generateEmbedding(for: query)

        var scoredSessions: [(session: ChatSession, score: Double)] = []

        for session in sessions {
            let sessionText = session.messages.map { $0.text }.joined(separator: " ")
            let sessionEmbedding = try await generateEmbedding(for: sessionText)

            let similarity = cosineSimilarity(queryEmbedding, sessionEmbedding)
            scoredSessions.append((session, similarity))
        }

        // Sort by similarity score and return top results
        return scoredSessions
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.session }
    }

    func searchWithinConversation(_ session: ChatSession, query: String) async throws -> [ChatMessage] {
        let queryEmbedding = try await generateEmbedding(for: query)

        var scoredMessages: [(message: ChatMessage, score: Double)] = []

        for message in session.messages {
            let messageEmbedding = try await generateEmbedding(for: message.text)
            let similarity = cosineSimilarity(queryEmbedding, messageEmbedding)
            scoredMessages.append((message, similarity))
        }

        return scoredMessages
            .sorted { $0.score > $1.score }
            .filter { $0.score > 0.3 } // Only return relevant results
            .map { $0.message }
    }

    // MARK: - Smart Suggestions
    func suggestFollowUpQuestions(for session: ChatSession) async throws -> [String] {
        let messages = session.messages.sorted { $0.timestamp < $1.timestamp }
        let recentMessages = messages.suffix(5).map { $0.isUser ? "User: \($0.text)" : "AI: \($0.text)" }.joined(separator: "\n")

        let prompt = """
        Based on this recent conversation, suggest 3 follow-up questions the user might ask:

        \(recentMessages)

        Suggestions:
        1.
        2.
        3.
        """

        let languageSession = try await LanguageModelSession(model: languageModel)
        let response = try await languageSession.respond(to: prompt)

        return response.content
            .components(separatedBy: "\n")
            .filter { $0.firstMatch(of: /^\d+\./) != nil }
            .map { $0.replacing(/^\d+\.\s*/, with: "") }
            .filter { !$0.isEmpty }
    }

    // MARK: - Content Analysis
    func analyzeSentiment(in session: ChatSession) async throws -> (positive: Double, neutral: Double, negative: Double) {
        let messages = session.messages.filter { $0.isUser }
        var sentiments: [Double] = []

        for message in messages {
            let sentiment = analyzeSentiment(of: message.text)
            sentiments.append(sentiment)
        }

        let positive = sentiments.filter { $0 > 0.1 }.count
        let negative = sentiments.filter { $0 < -0.1 }.count
        let neutral = sentiments.count - positive - negative

        let total = Double(sentiments.count)
        return (
            positive: total > 0 ? Double(positive) / total : 0,
            neutral: total > 0 ? Double(neutral) / total : 0,
            negative: total > 0 ? Double(negative) / total : 0
        )
    }

    func extractKeyTopics(from session: ChatSession) async throws -> [String] {
        let messages = session.messages.map { $0.text }.joined(separator: " ")

        let prompt = """
        Extract the 5 most important topics or themes from this conversation. List them as single words or short phrases:

        \(messages.prefix(1000))

        Topics:
        """

        let languageSession = try await LanguageModelSession(model: languageModel)
        let response = try await languageSession.respond(to: prompt)

        return response.content
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(5)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Private Helpers
    private func generateEmbedding(for text: String) async throws -> [Double] {
        // In a real implementation, this would use the language model's embedding capabilities
        // For now, we'll use a simple TF-IDF based approach
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var embedding: [Double] = []

        // Simple word frequency based embedding
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let wordCounts = Dictionary(words.map { ($0, 1) }, uniquingKeysWith: +)

        // Create a fixed-size embedding (simplified)
        let commonWords = ["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"]
        for word in commonWords {
            embedding.append(wordCounts[word, default: 0] > 0 ? 1.0 : 0.0)
        }

        return embedding
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        return magnitudeA > 0 && magnitudeB > 0 ? dotProduct / (magnitudeA * magnitudeB) : 0
    }

    private func analyzeSentiment(of text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var sentiment: Double = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, range in
            if let score = Double(tag?.rawValue ?? "0") {
                sentiment = score
            }
            return true
        }

        return sentiment
    }
}

// MARK: - Search View Model
@available(iOS 26.0, *)
@Observable
class SearchViewModel {
    var searchQuery = ""
    var searchResults: [ChatSession] = []
    var isSearching = false
    var selectedSession: ChatSession?

    private let searchService = AISearchService.shared
    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        searchService.setContext(context)
    }

    func performSearch() async {
        guard !searchQuery.isEmpty, let context = modelContext else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await searchService.searchConversations(query: searchQuery)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }

    func getSummary(for session: ChatSession) async -> String? {
        do {
            return try await searchService.summarizeConversation(session)
        } catch {
            print("Summary error: \(error)")
            return nil
        }
    }

    func getTopics(for session: ChatSession) async -> [String] {
        do {
            return try await searchService.extractKeyTopics(from: session)
        } catch {
            print("Topics error: \(error)")
            return []
        }
    }
}

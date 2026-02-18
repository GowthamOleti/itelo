//
//  ChatViewModel.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI
import Combine
import SwiftData
import Intents

@Observable
class ChatViewModel {
    var currentSession: ChatSession?
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isThinking: Bool = false
    var shouldTriggerImagePlayground: Bool = false
    var imagePrompt: String = ""
    var modelContext: ModelContext?
    
    // Switch this to CoreMLAIService() when you have the model file!
    private let aiService: AIService
    private let wordCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'’"))

    // iOS 26 Features
    private var siriSuggestionsService: SiriSuggestionsService?
    
    init() {
        #if canImport(FoundationModels)
        if #available(iOS 18.0, macOS 15.0, *) {
            // Try to use Apple Intelligence, but fall back to Mock if unavailable
            self.aiService = AppleIntelligenceServiceWithFallback()
        } else {
            self.aiService = MockAIService()
        }
        #else
        self.aiService = MockAIService()
        #endif
    }
    
    init(service: AIService) {
        self.aiService = service
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context

        // Initialize iOS 26 features
        if #available(iOS 26.0, *) {
            siriSuggestionsService = SiriSuggestionsService.shared
            siriSuggestionsService?.setContext(context)

            // Setup Siri suggestions
            siriSuggestionsService?.suggestBasedOnContext()
            siriSuggestionsService?.suggestBasedOnHistory()
            siriSuggestionsService?.createShortcuts()
        }
    }
    
    func loadSession(_ session: ChatSession) {
        self.currentSession = session
        self.messages = session.messages.sorted { $0.timestamp < $1.timestamp }

        // Index for Spotlight search
        if #available(iOS 26.0, *) {
            siriSuggestionsService?.indexChatSession(session)
        }
    }
    
    func createNewSession() {
        guard let context = modelContext else { return }
        let newSession = ChatSession()
        context.insert(newSession)
        self.currentSession = newSession
        self.messages = []
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let context = modelContext else { return }
        
        // Ensure we have a session
        if currentSession == nil {
            createNewSession()
        }
        
        guard let session = currentSession else { return }
        
        let lowercasedInput = inputText.lowercased()
        
        // Check for reminder command
        if lowercasedInput.contains("remind") || lowercasedInput.contains("reminder") {
            handleReminder()
            return
        }
        
        // Check for alarm command
        if lowercasedInput.contains("alarm") || lowercasedInput.contains("wake me") {
            handleAlarm()
            return
        }
        
        // Check for image generation command
        if (lowercasedInput.contains("generate") && lowercasedInput.contains("image")) ||
           (lowercasedInput.contains("create") && lowercasedInput.contains("image")) ||
           (lowercasedInput.contains("make") && lowercasedInput.contains("image")) ||
           (lowercasedInput.contains("draw") && lowercasedInput.contains("image")) ||
           lowercasedInput.starts(with: "/image") {
            
            let originalText = inputText
            var prompt = inputText
            let triggers = ["generate image of", "create image of", "make an image of", "draw an image of", "/image"]
            for trigger in triggers {
                if let range = prompt.range(of: trigger, options: .caseInsensitive) {
                    prompt.removeSubrange(range)
                    break
                }
            }
            imagePrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let userMessage = ChatMessage(text: originalText, isUser: true)
            userMessage.session = session
            session.messages.append(userMessage)
            messages.append(userMessage)
            
            shouldTriggerImagePlayground = true
            inputText = "" 
            return
        }
        
        let userMessage = ChatMessage(text: inputText, isUser: true)
        userMessage.session = session
        session.messages.append(userMessage)
        messages.append(userMessage)
        
        let prompt = inputText
        inputText = ""
        
        // Update session title if it's the first message
        if session.messages.count == 1 {
            session.title = String(prompt.prefix(30))
        }

        // Donate Siri intent for proactive suggestions
        if #available(iOS 26.0, *) {
            siriSuggestionsService?.donateChatIntent(with: prompt, sessionId: session.id)
        }
        
        // Simulate AI thinking
        isThinking = true
        
        Task {
            do {
                let responseStream = try await aiService.generateResponse(for: prompt)
                
                await MainActor.run {
                    self.isThinking = false
                    let aiMessage = ChatMessage(text: "", isUser: false)
                    aiMessage.session = session
                    session.messages.append(aiMessage)
                    self.messages.append(aiMessage)

                    // We need to keep track of this message to update it
                    self.streamResponse(responseStream, into: aiMessage)
                }
            } catch {
                await MainActor.run {
                    self.isThinking = false
                    let errorMessage = ChatMessage(text: "Sorry, I encountered an error: \(error.localizedDescription)", isUser: false)
                    errorMessage.session = session
                    session.messages.append(errorMessage)
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    private func streamResponse(_ stream: AsyncThrowingStream<String, Error>, into message: ChatMessage) {
        Task {
            var currentText = ""
            var isInsideWord = false
            var didTriggerGenerationHaptic = false

            do {
                for try await chunk in stream {
                    currentText.append(chunk)
                    let startedWords = countStartedWords(in: chunk, isInsideWord: &isInsideWord)
                    let shouldTriggerGenerationHaptic = !didTriggerGenerationHaptic
                    didTriggerGenerationHaptic = true

                    await MainActor.run {
                        if shouldTriggerGenerationHaptic {
                            HapticManager.shared.impact(style: .soft)
                        }

                        message.text = currentText

                        if startedWords > 0 {
                            for _ in 0..<startedWords {
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    HapticManager.shared.notification(type: .error)
                }
            }
        }
    }

    private func countStartedWords(in chunk: String, isInsideWord: inout Bool) -> Int {
        var startedWords = 0

        for character in chunk {
            if isWordCharacter(character) {
                if !isInsideWord {
                    startedWords += 1
                }
                isInsideWord = true
            } else {
                isInsideWord = false
            }
        }

        return startedWords
    }

    private func isWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { wordCharacterSet.contains($0) }
    }
    
    private func handleReminder() {
        guard let context = modelContext, let session = currentSession else { return }
        
        let userMessage = ChatMessage(text: inputText, isUser: true)
        userMessage.session = session
        session.messages.append(userMessage)
        messages.append(userMessage)
        
        let reminderText = TimeParser.extractReminderText(from: inputText)
        let dueDate = TimeParser.extractDateTime(from: inputText)
        
        inputText = ""
        isThinking = true
        
        Task {
            do {
                let result = try await ReminderService.shared.createReminder(title: reminderText, dueDate: dueDate)
                await MainActor.run {
                    self.isThinking = false
                    let responseMessage = ChatMessage(text: result, isUser: false)
                    responseMessage.session = session
                    session.messages.append(responseMessage)
                    self.messages.append(responseMessage)
                }
            } catch {
                await MainActor.run {
                    self.isThinking = false
                    let errorMessage = ChatMessage(text: "❌ \(error.localizedDescription)", isUser: false)
                    errorMessage.session = session
                    session.messages.append(errorMessage)
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    private func handleAlarm() {
        guard let context = modelContext, let session = currentSession else { return }
        
        let userMessage = ChatMessage(text: inputText, isUser: true)
        userMessage.session = session
        session.messages.append(userMessage)
        messages.append(userMessage)
        
        guard let alarmDate = TimeParser.extractDateTime(from: inputText) else {
            inputText = ""
            let errorMessage = ChatMessage(text: "❌ I couldn't understand the time. Try: 'Set alarm for 7am' or 'Wake me in 30 minutes'", isUser: false)
            errorMessage.session = session
            session.messages.append(errorMessage)
            messages.append(errorMessage)
            return
        }
        
        inputText = ""
        isThinking = true
        
        Task {
            await MainActor.run {
                self.isThinking = false
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                let responseMessage = ChatMessage(text: "⏰ Alarm functionality is not available. The requested time was: \(formatter.string(from: alarmDate))", isUser: false)
                responseMessage.session = session
                session.messages.append(responseMessage)
                self.messages.append(responseMessage)
            }
        }
    }
}

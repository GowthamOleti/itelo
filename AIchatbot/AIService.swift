//
//  AIService.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation
import CoreML

// MARK: - AI Service Protocol
protocol AIService {
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error>
}

// MARK: - Mock AI Service
class MockAIService: AIService {
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let responses = [
            "Ooh, that's a fun topic! Let me tell you what I know about \(prompt). 🌟",
            "Thinking... thinking... Got it! Here's the scoop on that. 🍦",
            "I'm feeling super helpful today! Let's dive into that. 🏊‍♂️",
            "Beep boop! Just kidding, I'm not a robot... well, kinda. Here's what you need to know! 🤖",
            "That's a great question! Let me sprinkle some knowledge on that for you. ✨"
        ]
        let responseText = responses.randomElement() ?? "I'm here to help and make your day brighter! ☀️"
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate thinking delay
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                for char in responseText {
                    // Simulate typing speed
                    try? await Task.sleep(nanoseconds: 30_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Apple Intelligence Service (Native)
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 18.0, macOS 15.0, *)
class AppleIntelligenceService: AIService {
    private let model = SystemLanguageModel.default
    
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check availability
                    let availability = await self.model.availability
                    guard availability == .available else {
                        throw NSError(domain: "AppleIntelligence", code: 1, userInfo: [NSLocalizedDescriptionKey: "System model not available. Check Settings > Apple Intelligence."])
                    }
                    
                    let session = try await LanguageModelSession(model: self.model)
                    
                    // Inject personality
                    let personalityPrompt = "You are a helpful, slightly light-hearted and fun assistant. Keep your responses concise and engaging. \n\nUser: \(prompt)"
                    
                    // Get the full response
                    let response = try await session.respond(to: personalityPrompt)
                    
                    // Manually stream it character by character for smooth UI
                    for char in response.content {
                        try? await Task.sleep(nanoseconds: 15_000_000) // 15ms per char
                        continuation.yield(String(char))
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Apple Intelligence Service with Fallback
@available(iOS 18.0, macOS 15.0, *)
class AppleIntelligenceServiceWithFallback: AIService {
    private let appleService = AppleIntelligenceService()
    private let mockService = MockAIService()
    
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        // Try Apple Intelligence first
        do {
            return try await appleService.generateResponse(for: prompt)
        } catch {
            // If it fails (model not available), fall back to mock
            print("Apple Intelligence unavailable, using mock service: \(error.localizedDescription)")
            return try await mockService.generateResponse(for: prompt)
        }
    }
}
#endif



// MARK: - CoreML AI Service (OpenELM)
class CoreMLAIService: AIService {
    // This is where you would load the actual CoreML model
    // e.g. private let model = try? OpenELM_3B_Instruct(configuration: MLModelConfiguration())
    
    private var isModelLoaded = false
    
    init() {
        // Placeholder for model loading logic
        // loadModel()
    }
    
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        guard isModelLoaded else {
            // Fallback if model is missing
            return try await MockAIService().generateResponse(for: "I am ready to run! Please uncomment the model loading code in AIService.swift.")
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                continuation.finish()
            }
        }
    }
}

// MARK: - Llama 3.2 Service (1B/3B)
class LlamaService: AIService {
    // UNCOMMENT THE LINES BELOW AFTER ADDING THE MODEL FILE TO XCODE
    /*
    private let model: Llama_3_2_3B_Instruct_4bit?

    init() {
         do {
             let config = MLModelConfiguration()
             config.computeUnits = .all // Use Neural Engine + GPU
             self.model = try Llama_3_2_3B_Instruct_4bit(configuration: config)
         } catch {
             print("Error loading Llama model: \(error)")
             self.model = nil
         }
    }
    
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        guard let model = model else {
            return try await MockAIService().generateResponse(for: "Llama model not loaded. Run scripts/download_models.sh and add the file to Xcode.")
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // This assumes the model has an 'input_ids' or text input.
                    // Many raw CoreML conversions need a tokenizer helper (since CoreML doesn't handle tokenization natively usually).
                    // For simplicity, we'll assume a wrapper or direct text input if the model supports it.
                    // IF the model requires tokenization (most do), we would need a tokenizer.json and a helper.
                    
                    // For now, let's keep it simple and safe.
                    // Real implementation requires: Tokenizer -> Input IDs -> Model -> Output IDs -> Detokenizer
                    
                    continuation.yield("Llama 3.2 is loaded! However, to run inference responsibly, we need to add the Tokenizer.swift helper to convert text to tensors. Check the 'swift-transformers' library.")
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    */
    
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        return try await MockAIService().generateResponse(for: "I'm ready for Llama 3.2! Run 'scripts/download_models.sh' to fetch the 3B model (~2GB).")
    }
}

// MARK: - Phi-3 Mini Service
// Microsoft's high-performance small model
class PhiService: AIService {
    func generateResponse(for prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        return try await MockAIService().generateResponse(for: "I'm pretending to be Phi-3! Great for reasoning tasks.")
    }
}

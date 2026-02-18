//
//  Tokenizer.swift
//  itelo
//
//  Created for Llama 3.2 support.
//

import Foundation

// MARK: - Integration Instructions
/*
 TO ENABLE TOKENIZATION FOR LLAMA 3.2:
 
 1. Add the 'swift-transformers' package:
    - In Xcode, go to File > Add Package Dependencies...
    - Search for: https://github.com/huggingface/swift-transformers
    - Click 'Add Package'
 
 2. Using it in your code:
    
    import Transformers
 
    let tokenizer = try await AutoTokenizer.from(pretrained: "meta-llama/Llama-3.2-3B-Instruct")
    let inputIds = tokenizer.encode("Hello, world!")
 
    // Pass inputIds to your CoreML model
 */

// MARK: - Placeholder Simple Tokenizer
// This is a very naive fallback that will NOT work well for a real LLM.
// It is here only to prevent compilation errors if you uncomment the LlamaService code 
// without adding the proper library.

class SimpleTokenizer {
    func encode(_ text: String) -> [Int] {
        // This is WRONG for Llama, but lets the code compile.
        // Llama 3 uses TikToken BPE.
        return text.utf8.map { Int($0) }
    }
    
    func decode(_ tokens: [Int]) -> String {
        let bytes = tokens.map { UInt8($0) }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}

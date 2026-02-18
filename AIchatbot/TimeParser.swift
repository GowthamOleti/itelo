//
//  TimeParser.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation

struct TimeParser {
    static func extractDateTime(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let now = Date()
        let calendar = Calendar.current
        
        // Handle "in X minutes/hours"
        if let minutes = extractMinutes(from: lowercased) {
            return calendar.date(byAdding: .minute, value: minutes, to: now)
        }
        
        if let hours = extractHours(from: lowercased) {
            return calendar.date(byAdding: .hour, value: hours, to: now)
        }
        
        // Handle "at X pm/am" or "at X:XX"
        if let time = extractTime(from: lowercased) {
            return time
        }
        
        // Handle "tomorrow at X"
        if lowercased.contains("tomorrow") {
            if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) {
                if let time = extractTime(from: lowercased) {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var components = calendar.dateComponents([.year, .month, .day], from: tomorrowDate)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    private static func extractMinutes(from text: String) -> Int? {
        let patterns = [
            "in (\\d+) minutes?",
            "after (\\d+) minutes?"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return Int(text[range])
            }
        }
        return nil
    }
    
    private static func extractHours(from text: String) -> Int? {
        let patterns = [
            "in (\\d+) hours?",
            "after (\\d+) hours?"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return Int(text[range])
            }
        }
        return nil
    }
    
    private static func extractTime(from text: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Pattern: "at 5pm", "at 5:30pm", "at 17:30"
        let patterns = [
            "at (\\d{1,2})\\s*(pm|am)",
            "at (\\d{1,2}):(\\d{2})\\s*(pm|am)?",
            "(\\d{1,2})\\s*(pm|am)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let hourRange = Range(match.range(at: 1), in: text)
                guard let hourRange = hourRange else { continue }
                guard var hour = Int(text[hourRange]) else { continue }
                
                var minute = 0
                if match.numberOfRanges > 2 {
                    if let minuteRange = Range(match.range(at: 2), in: text),
                       text[minuteRange].allSatisfy({ $0.isNumber }) {
                        minute = Int(text[minuteRange]) ?? 0
                    }
                }
                
                // Check for PM/AM
                if match.numberOfRanges > 3 {
                    if let periodRange = Range(match.range(at: match.numberOfRanges - 1), in: text) {
                        let period = String(text[periodRange]).lowercased()
                        if period == "pm" && hour < 12 {
                            hour += 12
                        } else if period == "am" && hour == 12 {
                            hour = 0
                        }
                    }
                }
                
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = hour
                components.minute = minute
                
                if let date = calendar.date(from: components), date > now {
                    return date
                } else if let date = calendar.date(from: components) {
                    // If time has passed today, schedule for tomorrow
                    return calendar.date(byAdding: .day, value: 1, to: date)
                }
            }
        }
        
        return nil
    }
    
    static func extractReminderText(from text: String) -> String {
        var cleaned = text
        
        // Remove trigger words
        let triggers = ["remind me to", "reminder to", "remind me", "set a reminder to", "set reminder"]
        for trigger in triggers {
            if let range = cleaned.range(of: trigger, options: .caseInsensitive) {
                cleaned.removeSubrange(range)
                break
            }
        }
        
        // Remove time expressions
        let timePatterns = [
            "in \\d+ (minutes?|hours?)",
            "at \\d{1,2}(:\\d{2})?\\s*(pm|am)?",
            "tomorrow",
            "after \\d+ (minutes?|hours?)"
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

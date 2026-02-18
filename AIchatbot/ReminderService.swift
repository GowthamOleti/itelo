//
//  ReminderService.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import Foundation
import EventKit

class ReminderService {
    static let shared = ReminderService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // Request calendar access
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToReminders()
            } else {
                return try await eventStore.requestAccess(to: .reminder)
            }
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    // Create a reminder
    func createReminder(title: String, dueDate: Date?) async throws -> String {
        let hasAccess = await requestAccess()
        guard hasAccess else {
            throw NSError(domain: "ReminderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied. Please enable in Settings."])
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = dueDateComponents
        }
        
        try eventStore.save(reminder, commit: true)
        
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "✅ Reminder set: \"\(title)\" for \(formatter.string(from: dueDate))"
        } else {
            return "✅ Reminder created: \"\(title)\""
        }
    }
}

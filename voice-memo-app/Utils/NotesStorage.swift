import Foundation
import SwiftUI

class NotesStorage {
    static let shared = NotesStorage()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "recorded_notes"
    
    func saveNotes(_ notes: [Note]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    func loadNotes() -> [Note] {
        if let data = userDefaults.data(forKey: storageKey),
           let notes = try? JSONDecoder().decode([Note].self, from: data) {
            return notes
        }
        return []
    }
}

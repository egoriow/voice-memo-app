import Foundation

// Add 'public' if needed
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    let audioURLString: String
    var transcription: String
    var summary: String
    var category: String
    let timestamp: Date
    
    var audioURL: URL? {
        // First try as a file URL
        if let url = URL(string: audioURLString), url.isFileURL {
            return url
        }
        // Then try as a path
        return URL(fileURLWithPath: audioURLString)
    }
    
    init(id: UUID = UUID(),
         title: String,
         audioURLString: String,
         transcription: String,
         summary: String,
         category: String,
         timestamp: Date) {
        self.id = id
        self.title = title
        self.audioURLString = audioURLString
        self.transcription = transcription
        self.summary = summary
        self.category = category
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, audioURLString, transcription, summary, category, timestamp
    }
} 

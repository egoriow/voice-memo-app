import Foundation

class GPTService {
    private let apiKey: String = "your-actual-openai-api-key" // Replace this with your key
    private let baseURL = "https://api.openai.com/v1"
    
    func processAudioNote(url: URL) async throws -> (transcription: String, summary: String, category: String) {
        // First, transcribe the audio
        let transcription = try await transcribeAudio(url: url)
        print("Transcription completed: \(transcription)")
        
        // Then, analyze the transcription
        let (summary, category) = try await analyzeText(transcription)
        print("Analysis completed - Summary: \(summary), Category: \(category)")
        
        return (transcription, summary, category)
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
        // Convert audio to correct format if needed
        let audioData: Data
        if url.pathExtension.lowercased() == "m4a" {
            audioData = try Data(contentsOf: url)
        } else {
            // Handle other formats if needed
            throw GPTError.apiError(message: "Unsupported audio format")
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        
        // Add model parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("whisper-1\r\n")
        
        // Add response format parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.append("text\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GPTError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(GPTErrorResponse.self, from: data)
            throw GPTError.apiError(message: errorResponse?.error.message ?? "Unknown error")
        }
        
        if let text = String(data: data, encoding: .utf8) {
            return text
        } else {
            throw GPTError.invalidResponse
        }
    }
    
    private func analyzeText(_ text: String) async throws -> (summary: String, category: String) {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Analyze the following text and provide:
        1. A concise summary (max 2 sentences)
        2. A single category that best describes the content (e.g., Personal, Work, Shopping, Ideas, etc.)
        
        Text: \(text)
        
        Respond in JSON format:
        {
            "summary": "...",
            "category": "..."
        }
        """
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that analyzes voice notes."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 200
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GPTError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(GPTErrorResponse.self, from: data)
            throw GPTError.apiError(message: errorResponse?.error.message ?? "Unknown error")
        }
        
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        
        guard let content = gptResponse.choices.first?.message.content,
              let analysisData = content.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(TextAnalysis.self, from: analysisData) else {
            throw GPTError.invalidResponse
        }
        
        return (analysis.summary, analysis.category)
    }
}

// Response models
struct TranscriptionResponse: Codable {
    let text: String
}

struct GPTResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct GPTErrorResponse: Codable {
    struct Error: Codable {
        let message: String
    }
    let error: Error
}

struct TextAnalysis: Codable {
    let summary: String
    let category: String
}

enum GPTError: Error {
    case invalidResponse
    case apiError(message: String)
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

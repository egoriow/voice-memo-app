import Foundation
import AVFoundation
import SwiftUI

@MainActor // Add this to make it safe to use on the main thread
class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private let audioSession = AVAudioSession.sharedInstance()
    private let gptService = GPTService()
    
    @Published var recordings: [Note] = []
    @Published var isRecording = false
    @Published var permissionDenied = false
    
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    override init() {
        super.init()
        setupSession()
        recordings = NotesStorage.shared.loadNotes()
        print("Documents directory: \(documentsPath)")
    }
    
    private func setupSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            // Request microphone permission
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self?.permissionDenied = true
                        print("Microphone access denied")
                    }
                }
            }
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        // First, make sure we're not already recording
        if isRecording {
            print("Already recording")
            return
        }
        
        // Ensure audio session is active
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Could not activate audio session: \(error)")
            return
        }
        
        // Create a filename without spaces or special characters
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = "\(dateFormatter.string(from: Date())).m4a"
        let audioFilename = documentsPath.appendingPathComponent(filename)
        print("Recording to file: \(audioFilename.path)")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                isRecording = true
                print("Recording started successfully")
            } else {
                print("Recording failed to start")
            }
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        processRecording()
        
        // Deactivate session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Could not deactivate audio session: \(error)")
        }
    }
    
    private func saveRecordings() {
        // Before saving, verify all audio files exist and are readable
        recordings = recordings.filter { note in
            if let url = note.audioURL {
                let exists = FileManager.default.fileExists(atPath: url.path)
                if !exists {
                    print("Warning: Audio file missing at \(url.path)")
                }
                return exists
            }
            return false
        }
        NotesStorage.shared.saveNotes(recordings)
    }
    
    private func processRecording() {
        guard let url = audioRecorder?.url else {
            print("No recording URL available")
            return
        }
        
        print("Processing recording at URL: \(url.path)")
        
        // Verify the file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path),
              FileManager.default.isReadableFile(atPath: url.path) else {
            print("Error: Recording file is missing or not readable at \(url.path)")
            return
        }
        
        // Create a new note with proper initialization
        let note = Note(
            id: UUID(),
            title: "Processing...",
            audioURLString: url.path,
            transcription: "Processing...",
            summary: "Processing...",
            category: "Processing...",
            timestamp: Date()
        )
        
        // Add to recordings array
        recordings.append(note)
        saveRecordings()
        
        // Process with GPT
        Task {
            do {
                let (transcription, summary, category) = try await gptService.processAudioNote(url: url)
                
                if let index = self.recordings.firstIndex(where: { $0.id == note.id }) {
                    var updatedNote = self.recordings[index]
                    updatedNote.transcription = transcription
                    updatedNote.summary = summary
                    updatedNote.category = category
                    updatedNote.title = "Note: \(summary.prefix(30))..."
                    self.recordings[index] = updatedNote
                    self.saveRecordings()
                }
            } catch {
                print("Error processing audio: \(error)")
                // Update note with error state
                if let index = self.recordings.firstIndex(where: { $0.id == note.id }) {
                    var updatedNote = self.recordings[index]
                    updatedNote.transcription = "Error processing recording"
                    updatedNote.summary = "Error"
                    updatedNote.category = "Error"
                    updatedNote.title = "Error processing recording"
                    self.recordings[index] = updatedNote
                    self.saveRecordings()
                }
            }
        }
    }
    
    deinit {
        audioRecorder?.stop()
        try? audioSession.setActive(false)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording did not finish successfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
        }
    }
}


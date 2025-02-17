import SwiftUI
import AVFoundation

struct NoteDetailView: View {
    let note: Note
    @StateObject private var audioPlayer = AudioPlayer()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Audio Player Controls
                VStack {
                    HStack {
                        Button(action: {
                            if audioPlayer.isPlaying {
                                audioPlayer.pause()
                            } else {
                                audioPlayer.play(url: note.audioURL)
                            }
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.black)
                        }
                        .disabled(note.audioURL == nil)
                        
                        if audioPlayer.duration > 0 {
                            HStack(spacing: 4) {
                                Text(formatTime(audioPlayer.currentTime))
                                Text("/")
                                Text(formatTime(audioPlayer.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = audioPlayer.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                
                // Transcription Section
                GroupBox("Transcription") {
                    if note.transcription.isEmpty {
                        ProgressView("Processing...")
                    } else {
                        Text(note.transcription)
                            .padding()
                    }
                }
                
                // Summary Section
                GroupBox("Summary") {
                    if note.summary.isEmpty {
                        ProgressView("Processing...")
                    } else {
                        Text(note.summary)
                            .padding()
                    }
                }
                
                // Category
                GroupBox("Category") {
                    Text(note.category)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    audioPlayer.stop()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingNotesList = false
    @State private var selectedCategory: String?
    
    var categories: [String: Int] {
        Dictionary(grouping: audioRecorder.recordings) { $0.category }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty && $0.key != "Processing..." && $0.key != "Error" }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Category Folders
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(categories.keys.sorted()), id: \.self) { category in
                                FolderView(
                                    category: category,
                                    count: categories[category] ?? 0,
                                    isSelected: category == selectedCategory
                                )
                                .onTapGesture {
                                    selectedCategory = category
                                    showingNotesList = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    .padding(.vertical)
                }
                
                Spacer()
                
                // Main recording button
                Button(action: {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red : Color.black)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 40))
                        )
                }
                .padding()
                .disabled(audioRecorder.permissionDenied)
                
                // Recording status
                Text(audioRecorder.permissionDenied ? "Microphone access denied" :
                     (audioRecorder.isRecording ? "Recording..." : "Tap to Record"))
                    .font(.headline)
                    .foregroundColor(audioRecorder.permissionDenied ? .red :
                                   (audioRecorder.isRecording ? .red : .primary))
                
                Spacer()
                
                // Notes list button
                Button(action: {
                    selectedCategory = nil
                    showingNotesList = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View All Notes (\(audioRecorder.recordings.count))")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Voice Notes")
            .sheet(isPresented: $showingNotesList) {
                NavigationStack {
                    NotesListView(
                        audioRecorder: audioRecorder,
                        filterCategory: selectedCategory
                    )
                }
            }
            .alert("Microphone Access Required", isPresented: .constant(audioRecorder.permissionDenied)) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to record voice notes.")
            }
        }
    }
}

struct FolderView: View {
    let category: String
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 50))
                    .foregroundColor(isSelected ? .black : .gray)
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .offset(y: 5)
            }
            
            Text(category)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

// Add 'public' if needed
struct NotesListView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNote: Note?
    let filterCategory: String?
    
    var filteredRecordings: [Note] {
        let sorted = audioRecorder.recordings.sorted(by: { $0.timestamp > $1.timestamp })
        if let category = filterCategory {
            return sorted.filter { $0.category == category }
        }
        return sorted
    }
    
    var body: some View {
        List {
            ForEach(filteredRecordings) { note in
                NoteRowView(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNote = note
                    }
            }
            .onDelete(perform: deleteNotes)
        }
        .navigationTitle(filterCategory ?? "All Voice Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .fullScreenCover(item: $selectedNote) { note in
            NavigationStack {
                NoteDetailView(note: note)
            }
        }
        .overlay(Group {
            if filteredRecordings.isEmpty {
                ContentUnavailableView(
                    filterCategory == nil ? "No Voice Notes" : "No Notes in Category",
                    systemImage: "mic.slash",
                    description: Text(filterCategory == nil ?
                                   "Start recording to create your first note" :
                                   "Record a note and categorize it as '\(filterCategory!)' to see it here")
                )
            }
        })
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        // Convert the index set to an array of notes
        let notesToDelete = offsets.map { filteredRecordings[$0] }
        
        // Remove the notes from the recordings array
        for note in notesToDelete {
            if let index = audioRecorder.recordings.firstIndex(where: { $0.id == note.id }) {
                audioRecorder.recordings.remove(at: index)
            }
        }
        
        // Save the updated recordings
        NotesStorage.shared.saveNotes(audioRecorder.recordings)
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
            Text(note.category)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(note.timestamp.formatted())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
} 

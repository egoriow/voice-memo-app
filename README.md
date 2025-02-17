# Voice Notes App

A SwiftUI-based iOS application that records voice memos, transcribes them using OpenAI's Whisper API, and provides AI-generated summaries and categorization.


## Features

- 🎤 Voice Recording: Record voice memos with high-quality audio
- 📝 Transcription: Automatic transcription using OpenAI's Whisper API
- 🤖 AI Analysis: Get summaries and categories for your voice notes using GPT-3.5
- 📂 Category Organization: Automatically organizes notes into categories
- 🎵 Audio Playback: Listen to your recorded voice notes
- 📱 iOS Native: Built with SwiftUI for a native iOS experience


## Requirements

- iOS 16.0+
- Xcode 15.0+
- OpenAI API Key
- Apple Developer Account (free account works for testing)


## Installation

1. Clone the repository:

bash
git clone https://github.com/yourusername/voice-memo-app.git

2. Open `voice-memo-app.xcodeproj` in Xcode

3. Add your OpenAI API key in `GPTService.swift`:

swift
private let apiKey: String = "your-openai-api-key-here"

4. Update the Bundle Identifier to something unique:
   - Select the project in Xcode's navigator
   - Select the target
   - Under "Signing & Capabilities", update the Bundle Identifier
   - Select your Team (Apple ID)

5. Add required privacy descriptions to Info.plist:

xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record voice memos.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to transcribe your voice memos.</string>


## Usage

1. Launch the app
2. Tap the microphone button to start recording
3. Tap again to stop recording
4. The app will automatically:
   - Transcribe your voice note
   - Generate a summary
   - Categorize the content
5. View your notes organized by categories
6. Tap any note to:
   - Play the audio
   - View the transcription
   - Read the summary
   - See the category


## Architecture

- **SwiftUI Views**:
  - `ContentView`: Main view with recording interface
  - `NotesListView`: List of recorded notes
  - `NoteDetailView`: Detailed view of a single note

- **Services**:
  - `GPTService`: Handles OpenAI API integration
  - `AudioRecorder`: Manages voice recording
  - `AudioPlayer`: Handles audio playback
  - `NotesStorage`: Manages local storage of notes


## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## License

This project is licensed under the MIT License - see the LICENSE file for details


## Acknowledgments

- OpenAI for Whisper and GPT APIs
- Apple for SwiftUI and AVFoundation
- The SwiftUI community for inspiration and support


## Support

For support, please open an issue in the repository or contact [projectuserfirst@gmail.com]

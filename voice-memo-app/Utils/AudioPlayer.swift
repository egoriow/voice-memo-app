import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var error: String?
    
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stop()
        try? audioSession.setActive(false)
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            self.error = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    func play(url: URL?) {
        guard let url = url else {
            self.error = "Invalid audio URL"
            return
        }
        
        // Verify file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.error = "Audio file is missing"
            print("File not found at path: \(url.path)")
            return
        }
        
        do {
            // Stop any existing playback
            stop()
            
            // Ensure audio session is active
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            // Create and configure new player with file URL
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            player?.prepareToPlay()
            
            duration = player?.duration ?? 0
            
            if player?.play() == true {
                isPlaying = true
                setupTimer()
                print("Playback started successfully")
            } else {
                throw NSError(domain: "AudioPlayer", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"])
            }
        } catch {
            self.error = "Failed to play audio: \(error.localizedDescription)"
            print("Playback error at \(url.path): \(error)")
            stop()
        }
    }
    
    private func setupTimer() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 0.1,
                           target: self,
                           selector: #selector(updateTime),
                           userInfo: nil,
                           repeats: true)
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    @objc private func updateTime() {
        guard let player = player, player.isPlaying else {
            timer?.invalidate()
            timer = nil
            isPlaying = false
            return
        }
        currentTime = player.currentTime
    }
    
    func pause() {
        player?.pause()
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
    
    func stop() {
        player?.stop()
        player?.delegate = nil
        player = nil
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        
        // Deactivate audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Could not deactivate audio session: \(error)")
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.error = "Audio decode error: \(error.localizedDescription)"
            }
            self?.stop()
        }
    }
}

import Foundation
import AVFoundation

// MARK: - Voice Recorder

/// Records short voice memos using AVAudioRecorder.
/// Outputs AAC-compressed M4A data suitable for QR code transmission.
///
/// Typical output sizes:
///   - 3 seconds → ~8-12 KB → ~15 QR frames
///   - 5 seconds → ~15-20 KB → ~25 QR frames
///   - 10 seconds → ~30-40 KB → ~50 QR frames
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordedDuration: TimeInterval = 0
    @Published var recordedData: Data?
    @Published var permissionDenied = false
    @Published var recordingProgress: Double = 0   // 0…1 relative to maxDuration
    
    /// Maximum recording duration in seconds.
    /// Longer recordings produce larger payloads that need more QR frames.
    static let maxDuration: TimeInterval = 10
    
    // MARK: - Private
    
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var recordingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("glyph_voice_memo.m4a")
    }
    
    // MARK: - Recording Settings
    
    /// AAC compression at low bitrate for QR-friendly file sizes.
    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,           // Half of CD quality — fine for voice
            AVNumberOfChannelsKey: 1,          // Mono
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey: 24000         // 24 kbps — very compact
        ]
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            permissionDenied = true
        case .undetermined:
            Task {
                let granted = await AVAudioApplication.requestRecordPermission()
                self.permissionDenied = !granted
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Record
    
    func startRecording() {
        // Check permission
        guard AVAudioApplication.shared.recordPermission == .granted else {
            requestPermission()
            return
        }
        
        // Configure audio session for recording
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Audio session setup failed: \(error)")
            #endif
            return
        }
        
        // Clean up any previous recording
        stopPlaying()
        recordedData = nil
        recordedDuration = 0
        recordingProgress = 0
        
        // Remove old file
        try? FileManager.default.removeItem(at: recordingURL)
        
        do {
            recorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            recorder?.delegate = self
            recorder?.record(forDuration: Self.maxDuration)
            isRecording = true
            
            // Progress timer
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, let rec = self.recorder, rec.isRecording else { return }
                    self.recordedDuration = rec.currentTime
                    self.recordingProgress = rec.currentTime / Self.maxDuration
                }
            }
        } catch {
            #if DEBUG
            print("Recording failed: \(error)")
            #endif
        }
    }
    
    func stopRecording() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        guard let rec = recorder, rec.isRecording else { return }
        rec.stop()
        isRecording = false
        
        // Load the recorded file
        loadRecordedData()
    }
    
    // MARK: - Playback
    
    func playRecording() {
        guard let data = recordedData else { return }
        do {
            // Switch to playback mode
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            #if DEBUG
            print("Playback failed: \(error)")
            #endif
        }
    }
    
    func stopPlaying() {
        player?.stop()
        player = nil
        isPlaying = false
    }
    
    func togglePlayback() {
        if isPlaying {
            stopPlaying()
        } else {
            playRecording()
        }
    }
    
    // MARK: - Data Export
    
    /// Returns base64-encoded M4A data for embedding in a GlyphMessage.
    var base64Audio: String? {
        recordedData?.base64EncodedString()
    }
    
    /// Formatted duration string (e.g. "3.2s")
    var durationString: String {
        String(format: "%.1fs", recordedDuration)
    }
    
    /// Estimated QR frame count
    var estimatedFrames: Int {
        guard let data = recordedData else { return 0 }
        return data.count / 800 + 1
    }
    
    /// File size in KB
    var fileSizeKB: String {
        guard let data = recordedData else { return "0" }
        return String(format: "%.1f", Double(data.count) / 1024.0)
    }
    
    // MARK: - Clear
    
    func clear() {
        stopRecording()
        stopPlaying()
        recordedData = nil
        recordedDuration = 0
        recordingProgress = 0
        try? FileManager.default.removeItem(at: recordingURL)
    }
    
    // MARK: - Private
    
    private func loadRecordedData() {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordingURL)
            recordedData = data
            #if DEBUG
            print("Voice memo: \(data.count) bytes (\(String(format: "%.1f", Double(data.count) / 1024.0)) KB) → ~\(data.count / 800 + 1) QR frames")
            #endif
        } catch {
            #if DEBUG
            print("Failed to load recording: \(error)")
            #endif
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            if flag {
                self.loadRecordedData()
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

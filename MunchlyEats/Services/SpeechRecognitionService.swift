import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Speech Recognition Service
@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    static let shared = SpeechRecognitionService()
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    // MARK: - Start Listening
    func startListening() {
        guard !isListening else { return }
        
        // Check authorization
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized. Please enable in Settings."
            return
        }
        
        // Check if recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available on this device."
            return
        }
        
        // Reset
        transcribedText = ""
        errorMessage = nil
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request."
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    // Ignore cancellation errors
                    if (error as NSError).code != 216 {
                        self.errorMessage = error.localizedDescription
                    }
                    self.stopListening()
                }
            }
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        guard isListening else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Reset
    func reset() {
        stopListening()
        transcribedText = ""
        errorMessage = nil
    }
}

// MARK: - Speech Synthesizer for AI Responses
class SpeechSynthesizerService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechSynthesizerService()
    
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

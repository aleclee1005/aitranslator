import Speech
import AVFoundation

@Observable
class SpeechRecognitionManager {
    var recognizedText = ""
    var isRecognizing = false
    var errorMessage: String?

    var onSentenceComplete: ((String) -> Void)?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var silenceTimer: Timer?
    private var lastSentText = ""

    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        return speechGranted && micGranted
    }

    func start(language: Language) throws {
        stop()
        errorMessage = nil
        recognizedText = ""
        lastSentText = ""

        recognizer = SFSpeechRecognizer(locale: language.sttLocale)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.requiresOnDeviceRecognition = false  // サーバー認識（安定性高い）
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                    self.resetSilenceTimer(text: text)
                }
            }
            if let error {
                let nsError = error as NSError
                // 1101 = local recognition unavailable, ignore and keep going
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 { return }
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecognizing = true
    }

    func stop() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecognizing = false
    }

    private func resetSilenceTimer(text: String) {
        silenceTimer?.invalidate()
        guard !text.isEmpty else { return }
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            let current = self.recognizedText
            guard !current.isEmpty, current != self.lastSentText else { return }
            self.lastSentText = current
            self.onSentenceComplete?(current)
        }
    }
}

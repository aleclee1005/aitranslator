import SwiftUI

struct ContentView: View {
    @State private var settings = AppSettings.shared
    @State private var speechManager = SpeechRecognitionManager()
    @State private var synthesizer = SpeechSynthesizer()
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var showSettings = false
    @State private var errorMessage: String?
    @State private var isTTSEnabled = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                languageSelector

                Divider()

                textPanel(
                    title: "原文",
                    text: speechManager.recognizedText,
                    placeholder: "开始说话..."
                )

                Divider()

                textPanel(
                    title: "译文",
                    text: translatedText,
                    placeholder: "翻译将在这里显示",
                    isLoading: isTranslating
                )

                Divider()

                controlButton
                    .padding(.vertical, 28)
            }
            .navigationTitle("AI 翻译")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("错误", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            speechManager.onSentenceComplete = { text in
                Task { await translate(text) }
            }
        }
    }

    // MARK: - Language Selector

    private var languageSelector: some View {
        HStack(spacing: 12) {
            languageMenu(selection: $settings.sourceLanguage)

            Button(action: swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }

            languageMenu(selection: $settings.targetLanguage)
        }
        .padding()
    }

    private func languageMenu(selection: Binding<Language>) -> some View {
        Menu {
            ForEach(Language.allCases) { lang in
                Button(lang.displayName) {
                    selection.wrappedValue = lang
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.wrappedValue.displayName)
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Text Panels

    private func textPanel(title: String, text: String, placeholder: String, isLoading: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.75)
                }
            }

            ScrollView {
                Text(text.isEmpty ? placeholder : text)
                    .font(.body)
                    .foregroundStyle(text.isEmpty ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeIn(duration: 0.15), value: text)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    // MARK: - Control Button

    private var controlButton: some View {
        HStack(spacing: 32) {
            Button(action: { isTTSEnabled.toggle() }) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 52, height: 52)
                    Image(systemName: isTTSEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title3)
                        .foregroundStyle(isTTSEnabled ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)

            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(speechManager.isRecognizing ? Color.red : Color.accentColor)
                        .frame(width: 72, height: 72)
                        .shadow(color: (speechManager.isRecognizing ? Color.red : Color.accentColor).opacity(0.4), radius: 8)
                    Image(systemName: speechManager.isRecognizing ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Button(action: swapLanguages) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 52, height: 52)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if speechManager.isRecognizing {
            speechManager.stop()
            synthesizer.stop()
        } else {
            translatedText = ""
            Task {
                let granted = await speechManager.requestPermissions()
                guard granted else {
                    errorMessage = "需要麦克风和语音识别权限，请在「设置」→「隐私」中开启。"
                    return
                }
                do {
                    try speechManager.start(language: settings.sourceLanguage)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func swapLanguages() {
        let temp = settings.sourceLanguage
        settings.sourceLanguage = settings.targetLanguage
        settings.targetLanguage = temp
        if speechManager.isRecognizing {
            speechManager.stop()
            try? speechManager.start(language: settings.sourceLanguage)
        }
    }

    private func translate(_ text: String) async {
        guard !text.isEmpty else { return }
        isTranslating = true
        defer { isTranslating = false }
        do {
            let result = try await TranslationService.translate(
                text: text,
                from: settings.sourceLanguage,
                to: settings.targetLanguage
            )
            translatedText = result
            if isTTSEnabled {
                synthesizer.speak(result, language: settings.targetLanguage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

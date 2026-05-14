import SwiftUI
import SwiftData
import Translation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settings = AppSettings.shared
    @State private var speechManager = SpeechRecognitionManager()
    @State private var synthesizer = SpeechSynthesizer()
    @State private var translatedText = ""
    @State private var recentTranslations: [(id: UUID, text: String)] = []
    @State private var isTranslating = false
    @State private var showSettings = false
    @State private var errorMessage: String?
    @State private var isTTSEnabled = true
    @State private var pendingEntries: [(original: String, translation: String)] = []
    @State private var appleTranslationService = AppleTranslationService()
    @State private var showHistory = false

    // Current in-progress speech (new text since last completed sentence)
    private var currentSpeech: String {
        let full = speechManager.recognizedText
        let sent = speechManager.lastSentText
        guard !sent.isEmpty, full.count > sent.count else {
            return sent.isEmpty ? full : ""
        }
        let idx = full.index(full.startIndex, offsetBy: sent.count)
        return String(full[idx...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                languageSelector

                Divider()

                if settings.recognitionMode == .meeting {
                    meetingPanels
                } else {
                    conversationPanels
                }

                Divider()

                controlButton
                    .padding(.vertical, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock")
                    }
                }
                ToolbarItem(placement: .principal) {
                    modePicker
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showHistory) { HistoryView() }
            .background(
                Color.clear
                    .translationTask(appleTranslationService.configuration) { session in
                        await appleTranslationService.handleSession(session)
                    }
                    .id(appleTranslationService.taskID)
            )
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            speechManager.onSentenceComplete = { text in
                Task { await translate(text) }
            }
        }
        .onChange(of: settings.recognitionMode) { _, _ in
            guard speechManager.isRecognizing else { return }
            speechManager.stop()
            try? speechManager.start(language: settings.sourceLanguage,
                                     mode: settings.recognitionMode)
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("", selection: $settings.recognitionMode) {
            Text("Conversation").tag(RecognitionMode.personal)
            Text("Meeting").tag(RecognitionMode.meeting)
        }
        .pickerStyle(.segmented)
        .frame(width: 154)
    }

    // MARK: - Conversation Panels (unchanged behavior)

    private var conversationPanels: some View {
        Group {
            textPanel(
                title: "Original",
                text: speechManager.recognizedText,
                placeholder: "Start speaking..."
            )
            Divider()
            textPanel(
                title: "Translation",
                text: translatedText,
                placeholder: "Translation will appear here",
                isLoading: isTranslating
            )
        }
    }

    // MARK: - Meeting Panels (rolling, auto-scroll)

    private var meetingPanels: some View {
        Group {
            // Original: only current in-progress sentence
            textPanel(
                title: "Original",
                text: currentSpeech,
                placeholder: "Start speaking...",
                isLoading: isTranslating
            )
            Divider()
            // Translation: rolling list, auto-scrolls to newest
            meetingTranslationPanel
        }
    }

    private var meetingTranslationPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translation")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(recentTranslations, id: \.id) { item in
                            Text(item.text)
                                .font(.body)
                                .foregroundStyle(
                                    item.id == recentTranslations.last?.id ? .primary : .secondary
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(item.id)
                        }
                        if recentTranslations.isEmpty {
                            Text("Translation will appear here")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .onChange(of: recentTranslations.count) { _, _ in
                    if let last = recentTranslations.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
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
                Button(lang.displayName) { selection.wrappedValue = lang }
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

    // MARK: - Text Panel

    private func textPanel(title: String, text: String, placeholder: String, isLoading: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if isLoading { ProgressView().scaleEffect(0.75) }
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
            saveCurrentSession()
        } else {
            translatedText = ""
            recentTranslations = []
            pendingEntries = []
            Task {
                let granted = await speechManager.requestPermissions()
                guard granted else {
                    errorMessage = String(localized: "Microphone and speech recognition permissions required. Enable in Settings → Privacy.")
                    return
                }
                do {
                    try speechManager.start(language: settings.sourceLanguage,
                                            mode: settings.recognitionMode)
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
            try? speechManager.start(language: settings.sourceLanguage,
                                     mode: settings.recognitionMode)
        }
    }

    private func translate(_ text: String) async {
        guard !text.isEmpty else { return }
        isTranslating = true
        defer { isTranslating = false }
        do {
            let result: String
            switch settings.translationEngine {
            case .apple:
                result = try await appleTranslationService.translate(
                    text: text,
                    from: settings.sourceLanguage,
                    to: settings.targetLanguage
                )
            case .groq:
                result = try await TranslationService.translate(
                    text: text,
                    from: settings.sourceLanguage,
                    to: settings.targetLanguage
                )
            }
            translatedText = result
            pendingEntries.append((original: text, translation: result))
            if settings.recognitionMode == .meeting {
                recentTranslations.append((id: UUID(), text: result))
                if recentTranslations.count > 4 { recentTranslations.removeFirst() }
            }
            if isTTSEnabled {
                synthesizer.speak(result, language: settings.targetLanguage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveCurrentSession() {
        guard !pendingEntries.isEmpty else { return }
        let session = Session(
            mode: settings.recognitionMode,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage
        )
        modelContext.insert(session)
        for pair in pendingEntries {
            let entry = TranscriptEntry(original: pair.original, translation: pair.translation)
            session.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        pendingEntries = []
    }
}

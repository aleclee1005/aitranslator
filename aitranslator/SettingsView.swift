import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var apiKey = ""
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            Form {
                privateSection
                onlineSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        KeychainService.save(key: "groq_api_key", value: apiKey)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                apiKey = KeychainService.load(key: "groq_api_key") ?? ""
            }
        }
    }

    // MARK: - Private & Offline

    private var privateSection: some View {
        Section {
            engineRow(
                engine: .apple,
                icon: "lock.shield.fill",
                iconColor: .green,
                title: "Apple Translation",
                subtitle: "Local · Fully offline"
            )
        } header: {
            Label("Private & Offline", systemImage: "externaldrive.fill")
                .textCase(nil)
                .font(.headline)
                .foregroundStyle(.primary)
        } footer: {
            Text("Voice and text data never leave your device. No network required.")
        }
    }

    // MARK: - Online API

    @ViewBuilder private var onlineSection: some View {
        Section {
            engineRow(
                engine: .groq,
                icon: "cloud.fill",
                iconColor: .blue,
                title: "Groq API",
                subtitle: "Cloud inference · Requires network"
            )

            if settings.translationEngine == .groq {
                apiKeyField
            }
        } header: {
            Label("Online API", systemImage: "network")
                .textCase(nil)
                .font(.headline)
                .foregroundStyle(.primary)
        } footer: {
            Text("Get API Key at console.groq.com\nNo commercial affiliation with Groq.")
        }

        Section {
            Picker("Retention Period", selection: $settings.retentionDays) {
                Text("7 Days").tag(7)
                Text("30 Days").tag(30)
                Text("90 Days").tag(90)
                Text("Forever").tag(0)
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - Subviews

    private func engineRow(
        engine: TranslationEngine,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            withAnimation { settings.translationEngine = engine }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if settings.translationEngine == engine {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var apiKeyField: some View {
        HStack {
            if showKey {
                TextField("gsk_...", text: $apiKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
            } else {
                SecureField("gsk_...", text: $apiKey)
            }
            Button {
                showKey.toggle()
            } label: {
                Image(systemName: showKey ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

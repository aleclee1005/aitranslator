import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: Session
    @Environment(\.modelContext) private var modelContext
    @State private var isSummarizing = false
    @State private var errorMessage: String?

    private var sortedEntries: [TranscriptEntry] {
        session.entries.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        List {
            if session.recognitionMode == .meeting {
                summarySection
            }
            transcriptSection
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: exportText()) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            if let summary = session.summary {
                Text(summary)
                    .font(.body)
                    .padding(.vertical, 4)
            } else {
                Button {
                    Task { await generateSummary() }
                } label: {
                    HStack {
                        if isSummarizing {
                            ProgressView().scaleEffect(0.85)
                            Text("Generating...")
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate Summary")
                        }
                    }
                }
                .disabled(isSummarizing)
            }
        } header: {
            Text("Summary")
        }
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        Section {
            ForEach(sortedEntries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.original)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(entry.translation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Transcript")
        }
    }

    // MARK: - Actions

    private func generateSummary() async {
        isSummarizing = true
        defer { isSummarizing = false }
        do {
            let summary = try await SummaryService.summarize(
                entries: sortedEntries,
                in: session.targetLang
            )
            session.summary = summary
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportText() -> String {
        var lines = [
            "I — Private Interpreter",
            session.date.formatted(date: .complete, time: .shortened),
            "\(session.sourceLang.displayName) → \(session.targetLang.displayName)",
            ""
        ]
        if let summary = session.summary {
            lines += ["=== Summary ===", summary, ""]
        }
        lines.append("=== Transcript ===")
        for entry in sortedEntries {
            lines += [entry.original, "→ \(entry.translation)", ""]
        }
        return lines.joined(separator: "\n")
    }
}


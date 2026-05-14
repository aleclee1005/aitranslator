import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Your conversation history will appear here.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRow(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { cleanupOldSessions() }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(sessions[i]) }
        try? modelContext.save()
    }

    private func cleanupOldSessions() {
        let days = settings.retentionDays
        guard days > 0 else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        sessions.filter { $0.date < cutoff }.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.recognitionMode == .meeting ? "person.3.fill" : "person.fill")
                .foregroundStyle(session.recognitionMode == .meeting ? .blue : .green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(session.sourceLang.displayName)
                    Image(systemName: "arrow.right").font(.caption2)
                    Text(session.targetLang.displayName)
                }
                .font(.subheadline).fontWeight(.medium)

                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(session.date, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(session.entries.count)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

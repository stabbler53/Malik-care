import SwiftUI
import SwiftData

/// Breastfeeding timer. The session is saved as it runs, so it keeps
/// counting even if the sheet is closed or the app is quit.
struct NursingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FeedEntry.start, order: .reverse) private var feeds: [FeedEntry]
    @State private var taps = 0

    private var active: FeedEntry? { feeds.first { $0.isRunning } }
    private var previousSide: BreastSide? {
        feeds.first { $0.kind == .nursing && $0.end != nil && $0.lastSide != nil }?.lastSide
    }
    /// Suggest the side opposite to the one the last feed ended on.
    private var suggestedSide: BreastSide? { active == nil ? previousSide?.other : nil }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                VStack(spacing: 20) {
                    if let previous = previousSide, active == nil {
                        Label("آخر رضعة انتهت على \(previous.title). ابدئي بـ\(previous.other.title).",
                              systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                            .cardStyle()
                    }

                    Text(Fmt.clock(active?.totalSeconds(at: ctx.date) ?? 0))
                        .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                        .padding(.top, 8)

                    // In right-to-left layout the first button sits on the right,
                    // matching the mother's right side.
                    HStack(spacing: 14) {
                        sideButton(.right, now: ctx.date)
                        sideButton(.left, now: ctx.date)
                    }

                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 0)

                    if let session = active {
                        Button {
                            session.finish()
                            try? context.save()
                            dismiss()
                        } label: {
                            Label("إنهاء وحفظ", systemImage: "checkmark")
                        }
                        .buttonStyle(BigButtonStyle(color: .nursing))

                        Button(role: .destructive) {
                            context.delete(session)
                            try? context.save()
                        } label: {
                            Text("إلغاء هذه الرضعة")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("رضاعة طبيعية")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: taps)
        }
    }

    private var hint: String {
        guard let session = active else { return "اضغطي على الجهة لبدء المؤقت" }
        return session.runningSide == nil
            ? "متوقف مؤقتاً. اضغطي على جهة للمتابعة"
            : "اضغطي على الجهة الأخرى للتبديل، أو على نفس الجهة للإيقاف المؤقت"
    }

    private func sideButton(_ side: BreastSide, now: Date) -> some View {
        let running = active?.runningSide == side
        let suggested = suggestedSide == side
        return Button { tap(side) } label: {
            VStack(spacing: 10) {
                Image(systemName: running ? "pause.fill" : "play.fill")
                    .font(.title)
                Text(side.title)
                    .font(.title2.bold())
                Text(Fmt.clock(active?.seconds(for: side, at: now) ?? 0))
                    .font(.title3.monospacedDigit())
                if suggested {
                    Text("التالية")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.25)))
                }
            }
            .foregroundStyle(running ? Color.white : Color.nursing)
            .frame(maxWidth: .infinity, minHeight: 190)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(running ? Color.nursing : Color.nursing.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.nursing, lineWidth: suggested ? 3 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(side.title)، \(running ? "إيقاف مؤقت" : "بدء")")
    }

    private func tap(_ side: BreastSide) {
        let session: FeedEntry
        if let existing = active {
            session = existing
        } else {
            session = FeedEntry(kind: .nursing)
            context.insert(session)
        }
        if session.runningSide == side {
            session.pause()
        } else {
            session.switchTo(side)
        }
        try? context.save()
        taps += 1
    }
}

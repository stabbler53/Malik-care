import SwiftUI
import SwiftData

/// "Wet" saves in one tap. "Dirty" and "mixed" open optional stool details.
struct DiaperView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: DiaperKind?
    @State private var color: StoolColor?
    @State private var consistency: StoolConsistency?
    @State private var note = ""
    @State private var time = Date.now
    @State private var saves = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(DiaperKind.allCases) { option in
                        Button { choose(option) } label: {
                            Label(option.title, systemImage: option.symbol)
                        }
                        .buttonStyle(BigButtonStyle(color: .diaper, filled: kind == option || kind == nil))
                    }

                    if kind == nil {
                        Text("المبلل يُحفظ مباشرة بضغطة واحدة")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let kind, kind.isDirty {
                        stoolDetails
                    }

                    TimeRow(date: $time)
                }
                .padding(16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if kind?.isDirty == true {
                    Button(action: save) {
                        Label("حفظ", systemImage: "checkmark")
                    }
                    .buttonStyle(BigButtonStyle(color: .diaper))
                    .padding(16)
                    .background(.bar)
                }
            }
            .navigationTitle("حفاض")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: saves)
        }
    }

    private var stoolDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("لون البراز (اختياري)")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(StoolColor.allCases) { option in
                    Button {
                        color = color == option ? nil : option
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: option.hex))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.secondary.opacity(0.4)))
                            Text(option.title)
                                .font(.footnote.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(color == option ? Color.diaper.opacity(0.25) : Color.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(color == option ? Color.diaper : Color.cardBorder, lineWidth: color == option ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let warning = color?.warning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.warning)
                    .cardStyle()
            }

            SectionTitle("القوام (اختياري)")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(StoolConsistency.allCases) { option in
                    Button {
                        consistency = consistency == option ? nil : option
                    } label: {
                        Text(option.title)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(consistency == option ? Color.white : Color.diaper)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(consistency == option ? Color.diaper : Color.diaper.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("ملاحظة (اختياري)", text: $note, axis: .vertical)
                .cardStyle()
        }
    }

    private func choose(_ option: DiaperKind) {
        if option == .wet {
            kind = .wet
            save()
        } else {
            withAnimation { kind = option }
        }
    }

    private func save() {
        guard let kind else { return }
        let entry = DiaperEntry(kind: kind, time: time)
        if kind.isDirty {
            entry.stoolColor = color
            entry.consistency = consistency
        }
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(entry)
        try? context.save()
        saves += 1
        dismiss()
    }
}

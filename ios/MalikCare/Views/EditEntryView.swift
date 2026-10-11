import SwiftUI
import SwiftData

/// Fix the time, amount or note of an entry, or delete it.
struct EditEntryView: View {
    let item: LogItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue

    init(item: LogItem) { self.item = item }

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    var body: some View {
        NavigationStack {
            Form {
                switch item {
                case .feed(let entry): FeedFields(entry: entry, unit: unit)
                case .diaper(let entry): DiaperFields(entry: entry)
                case .sleep(let entry): SleepFields(entry: entry)
                }
                Section {
                    Button("حذف هذا السجل", role: .destructive) {
                        switch item {
                        case .feed(let e): context.delete(e)
                        case .diaper(let e): context.delete(e)
                        case .sleep(let e): context.delete(e)
                        }
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("تعديل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct FeedFields: View {
    @Bindable var entry: FeedEntry
    let unit: VolumeUnit

    var body: some View {
        Section {
            DatePicker("البداية", selection: $entry.start, in: ...Date.now)
            switch entry.kind {
            case .nursing:
                Stepper("يمين: \(Fmt.duration(entry.rightSeconds))",
                        value: $entry.rightSeconds, in: 0...7200, step: 60)
                Stepper("يسار: \(Fmt.duration(entry.leftSeconds))",
                        value: $entry.leftSeconds, in: 0...7200, step: 60)
            case .bottle:
                Picker("النوع", selection: $entry.bottleContent) {
                    ForEach(BottleContent.allCases) { Text($0.title).tag($0) }
                }
                AmountStepper(ml: $entry.amountML, unit: unit, color: .bottle)
            case .pump:
                LabeledContent("الجهة اليمنى") { EmptyView() }
                AmountStepper(ml: $entry.rightML, unit: unit, color: .pump)
                LabeledContent("الجهة اليسرى") { EmptyView() }
                AmountStepper(ml: $entry.leftML, unit: unit, color: .pump)
            }
        }
        Section("ملاحظة") {
            TextField("ملاحظة", text: $entry.note, axis: .vertical)
        }
    }
}

private struct DiaperFields: View {
    @Bindable var entry: DiaperEntry

    var body: some View {
        Section {
            DatePicker("الوقت", selection: $entry.time, in: ...Date.now)
            Picker("النوع", selection: $entry.kindRaw) {
                ForEach(DiaperKind.allCases) { Text($0.title).tag($0.rawValue) }
            }
            if entry.kind.isDirty {
                Picker("اللون", selection: $entry.stoolColorRaw) {
                    Text("غير محدد").tag(String?.none)
                    ForEach(StoolColor.allCases) { Text($0.title).tag(Optional($0.rawValue)) }
                }
                Picker("القوام", selection: $entry.consistencyRaw) {
                    Text("غير محدد").tag(String?.none)
                    ForEach(StoolConsistency.allCases) { Text($0.title).tag(Optional($0.rawValue)) }
                }
            }
        }
        Section("ملاحظة") {
            TextField("ملاحظة", text: $entry.note, axis: .vertical)
        }
    }
}

private struct SleepFields: View {
    @Bindable var entry: SleepEntry

    private var endBinding: Binding<Date> {
        Binding(get: { entry.end ?? .now }, set: { entry.end = max($0, entry.start) })
    }

    var body: some View {
        Section {
            DatePicker("نام", selection: $entry.start, in: ...Date.now)
            if entry.end != nil {
                DatePicker("استيقظ", selection: endBinding, in: entry.start...Date.now)
                LabeledContent("المدة", value: Fmt.duration(entry.duration()))
            } else {
                LabeledContent("الحالة", value: "نائم الآن")
            }
        }
        Section("ملاحظة") {
            TextField("ملاحظة", text: $entry.note, axis: .vertical)
        }
    }
}

/// Log a nap after the fact, when the timer wasn't started.
struct AddSleepView: View {
    @Environment(\.modelContext) private var context
    @State private var start = Date.now.addingTimeInterval(-3600)
    @State private var end = Date.now

    var body: some View {
        LogSheet(title: "إضافة نوم سابق", color: .sleep, saveTitle: "حفظ", canSave: end > start, onSave: save) {
            DatePicker("نام", selection: $start, in: ...Date.now)
                .font(.headline)
                .cardStyle()
            DatePicker("استيقظ", selection: $end, in: start...Date.now)
                .font(.headline)
                .cardStyle()
            Text("المدة: " + Fmt.duration(end.timeIntervalSince(start)))
                .font(.headline)
        }
    }

    private func save() {
        context.insert(SleepEntry(start: start, end: end))
        try? context.save()
    }
}

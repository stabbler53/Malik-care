import SwiftUI
import SwiftData

struct BottleView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue
    @State private var content: BottleContent = .breastMilk
    @State private var ml: Double = 60
    @State private var time = Date.now

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    var body: some View {
        LogSheet(title: "رضّاعة", color: .bottle, saveTitle: "حفظ", canSave: ml > 0, onSave: save) {
            Picker("النوع", selection: $content) {
                ForEach(BottleContent.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            SectionTitle("الكمية")
            AmountStepper(ml: $ml, unit: unit, color: .bottle)
                .cardStyle()
            QuickAmounts(ml: $ml, unit: unit, color: .bottle)

            TimeRow(date: $time)
        }
    }

    private func save() {
        let entry = FeedEntry(kind: .bottle, start: time)
        entry.end = time
        entry.amountML = ml
        entry.bottleContent = content
        context.insert(entry)
        try? context.save()
    }
}

struct PumpView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue
    @State private var rightML: Double = 0
    @State private var leftML: Double = 0
    @State private var minutes = 15
    @State private var time = Date.now

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    var body: some View {
        LogSheet(title: "شفط الحليب", color: .pump, saveTitle: "حفظ", canSave: rightML + leftML > 0, onSave: save) {
            SectionTitle("الجهة اليمنى")
            AmountStepper(ml: $rightML, unit: unit, color: .pump)
                .cardStyle()

            SectionTitle("الجهة اليسرى")
            AmountStepper(ml: $leftML, unit: unit, color: .pump)
                .cardStyle()

            Text("المجموع: " + Fmt.volume(rightML + leftML, unit: unit))
                .font(.headline)

            Stepper(value: $minutes, in: 0...120, step: 5) {
                Text("المدة: " + Fmt.duration(Double(minutes * 60)))
                    .font(.headline)
            }
            .cardStyle()

            TimeRow(date: $time)
        }
    }

    private func save() {
        let entry = FeedEntry(kind: .pump, start: time)
        entry.end = time.addingTimeInterval(Double(minutes * 60))
        entry.rightML = rightML
        entry.leftML = leftML
        context.insert(entry)
        try? context.save()
    }
}

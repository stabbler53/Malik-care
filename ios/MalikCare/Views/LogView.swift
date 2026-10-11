import SwiftUI
import SwiftData

/// One row in the combined log.
enum LogItem: Identifiable {
    case feed(FeedEntry)
    case diaper(DiaperEntry)
    case sleep(SleepEntry)

    var id: PersistentIdentifier {
        switch self {
        case .feed(let e): e.persistentModelID
        case .diaper(let e): e.persistentModelID
        case .sleep(let e): e.persistentModelID
        }
    }

    var date: Date {
        switch self {
        case .feed(let e): e.start
        case .diaper(let e): e.time
        case .sleep(let e): e.start
        }
    }
}

struct DayGroup: Identifiable {
    let day: Date
    let items: [LogItem]
    var id: Date { day }
}

struct LogView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue
    @Query(sort: \FeedEntry.start, order: .reverse) private var feeds: [FeedEntry]
    @Query(sort: \DiaperEntry.time, order: .reverse) private var diapers: [DiaperEntry]
    @Query(sort: \SleepEntry.start, order: .reverse) private var sleeps: [SleepEntry]
    @State private var editing: LogItem?
    @State private var addingSleep = false

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    private var days: [DayGroup] {
        let all: [LogItem] = feeds.map(LogItem.feed) + diapers.map(LogItem.diaper) + sleeps.map(LogItem.sleep)
        let grouped = Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            DayGroup(day: day, items: grouped[day, default: []].sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        List {
            if feeds.isEmpty && diapers.isEmpty && sleeps.isEmpty {
                ContentUnavailableView("لا توجد سجلات بعد", systemImage: "list.bullet",
                                       description: Text("كل رضعة وحفاض ونوم تسجلينه سيظهر هنا."))
            }
            ForEach(days) { group in
                Section {
                    ForEach(group.items) { item in
                        Button { editing = item } label: { LogRow(item: item, unit: unit) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in delete(offsets.map { group.items[$0] }) }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Fmt.dayTitle(group.day)).font(.headline).foregroundStyle(.primary)
                        Text(daySummary(group.day)).font(.footnote)
                    }
                    .textCase(nil)
                }
                .listRowBackground(Color.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("سجل الأيام")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addingSleep = true } label: {
                    Label("إضافة نوم سابق", systemImage: "moon.badge.plus") // shown as icon
                }
            }
        }
        .sheet(item: $editing) { item in
            EditEntryView(item: item).arabic()
        }
        .sheet(isPresented: $addingSleep) {
            AddSleepView().arabic()
        }
    }

    private func daySummary(_ day: Date) -> String {
        let feedCount = Stats.feeds(feeds, on: day).count
        let diaperCount = Stats.diapers(diapers, on: day).count
        let sleep = Stats.sleepSeconds(sleeps, on: day)
        return "\(Fmt.count(feedCount)) رضعات · \(Fmt.count(diaperCount)) حفاضات · نوم \(Fmt.duration(sleep))"
    }

    private func delete(_ items: [LogItem]) {
        for item in items {
            switch item {
            case .feed(let e): context.delete(e)
            case .diaper(let e): context.delete(e)
            case .sleep(let e): context.delete(e)
            }
        }
        try? context.save()
    }
}

struct LogRow: View {
    let item: LogItem
    let unit: VolumeUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if !detail.isEmpty {
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(Fmt.time(item.date))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var symbol: String {
        switch item {
        case .feed(let e):
            switch e.kind {
            case .nursing: return "heart.fill"
            case .bottle: return "waterbottle.fill"
            case .pump: return "drop.circle.fill"
            }
        case .diaper(let e): return e.kind.symbol
        case .sleep: return "moon.fill"
        }
    }

    private var color: Color {
        switch item {
        case .feed(let e):
            switch e.kind {
            case .nursing: return .nursing
            case .bottle: return .bottle
            case .pump: return .pump
            }
        case .diaper: return .diaper
        case .sleep: return .sleep
        }
    }

    private var title: String {
        switch item {
        case .feed(let e):
            switch e.kind {
            case .nursing: return "رضاعة طبيعية"
            case .bottle: return "رضّاعة"
            case .pump: return "شفط الحليب"
            }
        case .diaper(let e): return "حفاض " + e.kind.title
        case .sleep: return "نوم"
        }
    }

    private var detail: String {
        switch item {
        case .feed(let e):
            switch e.kind {
            case .nursing:
                if e.isRunning { return "جارية الآن" }
                return "يمين \(Fmt.duration(e.rightSeconds)) · يسار \(Fmt.duration(e.leftSeconds))"
            case .bottle:
                return Fmt.volume(e.amountML, unit: unit) + " · " + e.bottleContent.title
            case .pump:
                let minutes = (e.end ?? e.start).timeIntervalSince(e.start)
                return "يمين \(Fmt.volume(e.rightML, unit: unit)) · يسار \(Fmt.volume(e.leftML, unit: unit)) · \(Fmt.duration(minutes))"
            }
        case .diaper(let e):
            let parts = [e.stoolColor?.title, e.consistency?.title, e.note.isEmpty ? nil : e.note].compactMap { $0 }
            return parts.joined(separator: " · ")
        case .sleep(let e):
            guard let end = e.end else { return "نائم الآن" }
            return "\(Fmt.duration(e.duration())) · حتى \(Fmt.time(end))"
        }
    }
}

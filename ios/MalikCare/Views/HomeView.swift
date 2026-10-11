import SwiftUI
import SwiftData

enum HomeSheet: String, Identifiable {
    case nursing, bottle, pump, diaper, settings
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.babyName) private var babyName = Defaults.babyName
    @AppStorage(Keys.motherName) private var motherName = Defaults.motherName
    @AppStorage(Keys.birthDate) private var birthDate = 0.0
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue
    @AppStorage(Keys.nightMode) private var nightMode = NightMode.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    @Query private var feeds: [FeedEntry]
    @Query private var diapers: [DiaperEntry]
    @Query private var sleeps: [SleepEntry]

    @State private var sheet: HomeSheet?
    @State private var sleepToggles = 0

    init() {
        // The home screen only needs the last couple of days.
        let cutoff = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .distantPast
        _feeds = Query(filter: #Predicate<FeedEntry> { $0.start >= cutoff }, sort: \FeedEntry.start, order: .reverse)
        _diapers = Query(filter: #Predicate<DiaperEntry> { $0.time >= cutoff }, sort: \DiaperEntry.time, order: .reverse)
        _sleeps = Query(filter: #Predicate<SleepEntry> { $0.start >= cutoff }, sort: \SleepEntry.start, order: .reverse)
    }

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }
    private var activeNursing: FeedEntry? { feeds.first { $0.isRunning } }
    private var activeSleep: SleepEntry? { sleeps.first { $0.isRunning } }
    private var lastFeed: FeedEntry? { feeds.first { $0.kind != .pump } }
    private var lastNursingSide: BreastSide? { feeds.first { $0.kind == .nursing && $0.lastSide != nil }?.lastSide }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header(now: ctx.date)
                    if let nursing = activeNursing {
                        RunningBanner(title: nursing.runningSide.map { "رضاعة من \($0.title)" } ?? "الرضاعة متوقفة مؤقتاً",
                                      symbol: "heart.fill", color: .nursing, since: nursing.start,
                                      seconds: { nursing.totalSeconds(at: $0) })
                            .onTapGesture { sheet = .nursing }
                    }
                    if let sleep = activeSleep {
                        RunningBanner(title: "\(babyName) نائم", symbol: "moon.zzz.fill", color: .sleep,
                                      since: sleep.start, seconds: { sleep.duration(at: $0) })
                    }
                    summary(now: ctx.date)
                    NavigationLink {
                        LogView().arabic()
                    } label: {
                        Label("سجل الأيام", systemImage: "list.bullet.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.secondary)
                }
                .padding(16)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { actionPad }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $sheet) { sheet in
            sheetContent(sheet).arabic()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: sleepToggles)
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("مرحباً \(motherName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(babyName)
                    .font(.largeTitle.bold())
                if birthDate > 0 {
                    Text("عمره " + Fmt.age(birth: Date(timeIntervalSince1970: birthDate), now: now))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                nightMode = colorScheme == .dark ? NightMode.light.rawValue : NightMode.dark.rawValue
            } label: {
                Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                    .font(.title2)
                    .frame(width: 52, height: 52)
            }
            .accessibilityLabel("الوضع الليلي")
            Button { sheet = .settings } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .frame(width: 52, height: 52)
            }
            .accessibilityLabel("الإعدادات")
        }
        .foregroundStyle(.primary)
    }

    // MARK: Summary

    private func summary(now: Date) -> some View {
        let todayFeeds = Stats.feeds(feeds, on: now)
        let todayDiapers = Stats.diapers(diapers, on: now)
        let wet = todayDiapers.filter { $0.kind.isWet }.count
        let dirty = todayDiapers.filter { $0.kind.isDirty }.count
        let bottle = Stats.bottleML(feeds, on: now)

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            SummaryCard(title: "آخر رضعة", symbol: "clock.fill", color: .nursing,
                        value: lastFeed.map { Fmt.ago($0.start, now: now) } ?? "لا يوجد بعد",
                        detail: lastNursingSide.map { "آخر جهة: \($0.title)" })
            SummaryCard(title: "الرضعات اليوم", symbol: "heart.fill", color: .bottle,
                        value: Fmt.count(todayFeeds.count),
                        detail: bottle > 0 ? "رضّاعة: " + Fmt.volume(bottle, unit: unit) : nil)
            SummaryCard(title: "الحفاضات اليوم", symbol: "drop.fill", color: .diaper,
                        value: Fmt.count(todayDiapers.count),
                        detail: "\(Fmt.count(wet)) مبلل · \(Fmt.count(dirty)) متسخ")
            SummaryCard(title: "النوم اليوم", symbol: "moon.fill", color: .sleep,
                        value: Fmt.duration(Stats.sleepSeconds(sleeps, on: now, now: now)),
                        detail: Stats.wakeWindow(sleeps, now: now).map { "مستيقظ منذ " + Fmt.duration($0) })
        }
    }

    // MARK: Action pad (bottom, within thumb reach)

    private var actionPad: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { sheet = .nursing } label: {
                    Label(activeNursing == nil ? "رضاعة طبيعية" : "الرضاعة جارية", systemImage: "heart.fill")
                }
                .buttonStyle(BigButtonStyle(color: .nursing))

                Button { sheet = .diaper } label: {
                    Label("حفاض", systemImage: "drop.fill")
                }
                .buttonStyle(BigButtonStyle(color: .diaper))
            }
            HStack(spacing: 10) {
                Button(action: toggleSleep) {
                    Label(activeSleep == nil ? "نام" : "استيقظ",
                          systemImage: activeSleep == nil ? "moon.zzz.fill" : "sun.max.fill")
                }
                .buttonStyle(BigButtonStyle(color: .sleep))

                Button { sheet = .bottle } label: {
                    Label("رضّاعة", systemImage: "waterbottle.fill")
                }
                .buttonStyle(BigButtonStyle(color: .bottle))
            }
            Button { sheet = .pump } label: {
                Label("شفط الحليب", systemImage: "drop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(BigButtonStyle(color: .pump, filled: false))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private func toggleSleep() {
        if let sleep = activeSleep {
            sleep.end = .now
        } else {
            context.insert(SleepEntry(start: .now))
        }
        try? context.save()
        sleepToggles += 1
    }

    @ViewBuilder
    private func sheetContent(_ sheet: HomeSheet) -> some View {
        switch sheet {
        case .nursing: NursingView()
        case .bottle: BottleView()
        case .pump: PumpView()
        case .diaper: DiaperView()
        case .settings: SettingsView()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let symbol: String
    let color: Color
    let value: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(detail ?? " ")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .cardStyle()
    }
}

struct RunningBanner: View {
    let title: String
    let symbol: String
    let color: Color
    let since: Date
    let seconds: (Date) -> Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text("بدأ " + Fmt.time(since)).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Text(Fmt.clock(seconds(ctx.date)))
                    .font(.title2.bold().monospacedDigit())
            }
            .cardStyle()
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color, lineWidth: 2))
        }
    }
}

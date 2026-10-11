import Foundation
import SwiftData

// All data lives only on this iPhone (SwiftData, no iCloud, no sync).
// Enums are stored as raw strings so the schema stays simple to migrate later.

enum FeedKind: String, CaseIterable {
    case nursing, bottle, pump
}

enum BreastSide: String, CaseIterable {
    case right, left

    var title: String { self == .right ? "اليمين" : "اليسار" }
    var other: BreastSide { self == .right ? .left : .right }
}

enum BottleContent: String, CaseIterable, Identifiable {
    case breastMilk, formula

    var id: String { rawValue }
    var title: String { self == .breastMilk ? "حليب الأم" : "حليب صناعي" }
}

@Model
final class FeedEntry {
    var kindRaw: String = FeedKind.nursing.rawValue
    var start: Date = Date()
    /// nil while a nursing session is still running.
    var end: Date?

    // Nursing
    var rightSeconds: Double = 0
    var leftSeconds: Double = 0
    var runningSideRaw: String?
    var runningSince: Date?
    var lastSideRaw: String?

    // Bottle
    var amountML: Double = 0
    var bottleContentRaw: String?

    // Pump
    var rightML: Double = 0
    var leftML: Double = 0

    var note: String = ""

    init(kind: FeedKind, start: Date = .now) {
        self.kindRaw = kind.rawValue
        self.start = start
    }

    var kind: FeedKind { FeedKind(rawValue: kindRaw) ?? .nursing }
    var isRunning: Bool { kind == .nursing && end == nil }

    var runningSide: BreastSide? {
        get { runningSideRaw.flatMap(BreastSide.init(rawValue:)) }
        set { runningSideRaw = newValue?.rawValue }
    }

    var lastSide: BreastSide? {
        get { lastSideRaw.flatMap(BreastSide.init(rawValue:)) }
        set { lastSideRaw = newValue?.rawValue }
    }

    var bottleContent: BottleContent {
        get { bottleContentRaw.flatMap(BottleContent.init(rawValue:)) ?? .breastMilk }
        set { bottleContentRaw = newValue.rawValue }
    }

    func seconds(for side: BreastSide, at now: Date = .now) -> Double {
        var total = side == .right ? rightSeconds : leftSeconds
        if runningSide == side, let since = runningSince {
            total += max(0, now.timeIntervalSince(since))
        }
        return total
    }

    func totalSeconds(at now: Date = .now) -> Double {
        seconds(for: .right, at: now) + seconds(for: .left, at: now)
    }

    /// Starts the timer on `side`, banking any time on the other side first.
    func switchTo(_ side: BreastSide, at now: Date = .now) {
        pause(at: now)
        if rightSeconds == 0 && leftSeconds == 0 { start = now }
        runningSide = side
        runningSince = now
        lastSide = side
    }

    func pause(at now: Date = .now) {
        if let side = runningSide, let since = runningSince {
            let elapsed = max(0, now.timeIntervalSince(since))
            if side == .right { rightSeconds += elapsed } else { leftSeconds += elapsed }
        }
        runningSide = nil
        runningSince = nil
    }

    func finish(at now: Date = .now) {
        pause(at: now)
        end = now
    }
}

enum DiaperKind: String, CaseIterable, Identifiable {
    case wet, dirty, mixed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .wet: "مبلل"
        case .dirty: "متسخ"
        case .mixed: "مبلل ومتسخ"
        }
    }
    var symbol: String {
        switch self {
        case .wet: "drop.fill"
        case .dirty: "circle.fill"
        case .mixed: "circle.lefthalf.filled"
        }
    }
    var isWet: Bool { self != .dirty }
    var isDirty: Bool { self != .wet }
}

enum StoolColor: String, CaseIterable, Identifiable {
    case yellow, green, brown, black, red, pale

    var id: String { rawValue }
    var title: String {
        switch self {
        case .yellow: "أصفر"
        case .green: "أخضر"
        case .brown: "بني"
        case .black: "أسود"
        case .red: "أحمر"
        case .pale: "أبيض أو شاحب"
        }
    }
    var hex: UInt32 {
        switch self {
        case .yellow: 0xE8C547
        case .green: 0x6B8E3D
        case .brown: 0x8B5A2B
        case .black: 0x222222
        case .red: 0xC0392B
        case .pale: 0xEDE8DA
        }
    }
    /// A gentle note shown when a colour can need a doctor's attention.
    var warning: String? {
        switch self {
        case .red: "اللون الأحمر قد يعني وجود دم. يُنصح بالتواصل مع طبيب الأطفال."
        case .pale: "البراز الأبيض أو الشاحب قد يدل على مشكلة في الكبد. تواصلي مع طبيب الأطفال في أقرب وقت."
        case .black: "الأسود طبيعي في الأيام الأولى بعد الولادة. إن استمر بعدها، استشيري الطبيب."
        default: nil
        }
    }
}

enum StoolConsistency: String, CaseIterable, Identifiable {
    case watery, soft, seedy, firm, hard

    var id: String { rawValue }
    var title: String {
        switch self {
        case .watery: "سائل"
        case .soft: "طري"
        case .seedy: "حبيبي"
        case .firm: "متماسك"
        case .hard: "قاسٍ"
        }
    }
}

@Model
final class DiaperEntry {
    var time: Date = Date()
    var kindRaw: String = DiaperKind.wet.rawValue
    var stoolColorRaw: String?
    var consistencyRaw: String?
    var note: String = ""

    init(kind: DiaperKind, time: Date = .now) {
        self.kindRaw = kind.rawValue
        self.time = time
    }

    var kind: DiaperKind { DiaperKind(rawValue: kindRaw) ?? .wet }
    var stoolColor: StoolColor? {
        get { stoolColorRaw.flatMap(StoolColor.init(rawValue:)) }
        set { stoolColorRaw = newValue?.rawValue }
    }
    var consistency: StoolConsistency? {
        get { consistencyRaw.flatMap(StoolConsistency.init(rawValue:)) }
        set { consistencyRaw = newValue?.rawValue }
    }
}

@Model
final class SleepEntry {
    var start: Date = Date()
    /// nil while Malik is still asleep.
    var end: Date?
    var note: String = ""

    init(start: Date = .now, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    var isRunning: Bool { end == nil }

    func duration(at now: Date = .now) -> Double {
        max(0, (end ?? now).timeIntervalSince(start))
    }
}

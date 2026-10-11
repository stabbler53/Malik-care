import Foundation

/// Daily totals shown on the home screen and in the log.
enum Stats {
    static func dayRange(_ day: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return (start, end)
    }

    /// Seconds of sleep that fall inside the given calendar day (naps crossing midnight are split).
    static func sleepSeconds(_ sleeps: [SleepEntry], on day: Date, now: Date = .now) -> Double {
        let range = dayRange(day)
        let limit = min(range.end, now)
        return sleeps.reduce(0) { sum, s in
            let from = max(s.start, range.start)
            let to = min(s.end ?? now, limit)
            return sum + max(0, to.timeIntervalSince(from))
        }
    }

    static func feeds(_ feeds: [FeedEntry], on day: Date) -> [FeedEntry] {
        let range = dayRange(day)
        return feeds.filter { $0.kind != .pump && $0.start >= range.start && $0.start < range.end }
    }

    static func diapers(_ diapers: [DiaperEntry], on day: Date) -> [DiaperEntry] {
        let range = dayRange(day)
        return diapers.filter { $0.time >= range.start && $0.time < range.end }
    }

    static func bottleML(_ feeds: [FeedEntry], on day: Date) -> Double {
        Self.feeds(feeds, on: day).filter { $0.kind == .bottle }.reduce(0) { $0 + $1.amountML }
    }

    /// Time awake since the last sleep ended; nil while asleep or with no sleep logged.
    static func wakeWindow(_ sleeps: [SleepEntry], now: Date = .now) -> Double? {
        if sleeps.contains(where: { $0.isRunning }) { return nil }
        guard let lastEnd = sleeps.compactMap(\.end).max() else { return nil }
        return now.timeIntervalSince(lastEnd)
    }
}

import Foundation

/// Arabic text helpers. Numbers use Arabic-Indic digits throughout.
enum Fmt {
    static let locale = Locale(identifier: "ar")

    static func digits(_ text: String) -> String {
        let arabic: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(text.map { ch in
            if let value = ch.wholeNumberValue, ch.isASCII { return arabic[value] }
            return ch
        })
    }

    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }

    static func count(_ value: Int) -> String { digits(String(value)) }

    /// Stopwatch style, e.g. ٠٥:٠٧ or ١:٠٥:٠٧
    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        let text = h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
        return digits(text)
    }

    /// Short duration, e.g. "١ س ٢٠ د" or "٤٥ د".
    static func duration(_ seconds: Double) -> String {
        let minutes = Int(max(0, seconds) / 60)
        if minutes < 1 { return "أقل من دقيقة" }
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return digits("\(m)") + " د" }
        if m == 0 { return digits("\(h)") + " س" }
        return digits("\(h)") + " س " + digits("\(m)") + " د"
    }

    static func ago(_ date: Date, now: Date = .now) -> String {
        "منذ " + duration(now.timeIntervalSince(date))
    }

    static func time(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }

    static func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "اليوم" }
        if cal.isDateInYesterday(day) { return "أمس" }
        return day.formatted(Date.FormatStyle(date: .complete, time: .omitted).locale(locale))
    }

    static func volume(_ ml: Double, unit: VolumeUnit) -> String {
        number(unit.fromML(ml)) + " " + unit.title
    }

    /// Arabic counted noun: ١ يوم، يومان، ٣ أيام، ١١ يوماً
    static func counted(_ n: Int, one: String, two: String, few: String, many: String) -> String {
        switch n {
        case 1: return one
        case 2: return two
        case 3...10: return count(n) + " " + few
        default: return count(n) + " " + many
        }
    }

    static func age(birth: Date, now: Date = .now) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: birth), to: cal.startOfDay(for: now)).day ?? 0
        if days < 1 { return "مولود اليوم" }
        if days < 28 {
            return counted(days, one: "يوم واحد", two: "يومان", few: "أيام", many: "يوماً")
        }
        if days < 91 {
            let weeks = days / 7
            return counted(weeks, one: "أسبوع واحد", two: "أسبوعان", few: "أسابيع", many: "أسبوعاً")
        }
        let months = cal.dateComponents([.month], from: birth, to: now).month ?? 0
        return counted(months, one: "شهر واحد", two: "شهران", few: "أشهر", many: "شهراً")
    }
}

import SwiftUI

enum Keys {
    static let babyName = "babyName"
    static let motherName = "motherName"
    static let birthDate = "birthDate"     // timeIntervalSince1970, 0 = not set
    static let volumeUnit = "volumeUnit"
    static let nightMode = "nightMode"
}

enum Defaults {
    static let babyName = "مالك"
    static let motherName = "نشوى"
}

enum VolumeUnit: String, CaseIterable, Identifiable {
    case ml, oz

    static let mlPerOz = 29.5735

    var id: String { rawValue }
    var title: String { self == .ml ? "مل" : "أونصة" }
    var step: Double { self == .ml ? 10 : 0.5 }
    var quickAmounts: [Double] { self == .ml ? [30, 60, 90, 120, 150] : [1, 2, 3, 4, 5] }

    func fromML(_ ml: Double) -> Double { self == .ml ? ml : ml / Self.mlPerOz }
    func toML(_ value: Double) -> Double { self == .ml ? value : value * Self.mlPerOz }
}

enum NightMode: String, CaseIterable, Identifiable {
    case system, dark, light

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "حسب الجهاز"
        case .dark: "ليلي دائماً"
        case .light: "نهاري دائماً"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

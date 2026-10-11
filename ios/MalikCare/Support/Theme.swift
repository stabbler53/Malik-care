import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Warm cream by day, true OLED black by night.
    static let appBackground = dynamic(light: 0xFBF6F1, dark: 0x000000)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x111111)
    static let cardBorder = dynamic(light: 0xEFE6DD, dark: 0x1E1E1E)

    // Night colours are deliberately dim so the screen doesn't light up the room.
    static let nursing = dynamic(light: 0xE07A8B, dark: 0x8A4A55)
    static let bottle = dynamic(light: 0xF0A060, dark: 0x8C5E38)
    static let pump = dynamic(light: 0xA88BD6, dark: 0x5E4E7A)
    static let diaper = dynamic(light: 0x4FB3A9, dark: 0x2F6B65)
    static let sleep = dynamic(light: 0x6B7FD7, dark: 0x3E4A80)
    static let warning = dynamic(light: 0xC0392B, dark: 0xB0574C)
}

/// Forces the Arabic right-to-left layout and Arabic dates everywhere,
/// including inside sheets.
struct ArabicEnvironment: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Fmt.locale)
    }
}

extension View {
    func arabic() -> some View { modifier(ArabicEnvironment()) }

    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardBorder))
    }
}

/// The large, thumb-friendly button used for every main action.
struct BigButtonStyle: ButtonStyle {
    var color: Color
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .foregroundStyle(filled ? Color.white : color)
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(filled ? color : color.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

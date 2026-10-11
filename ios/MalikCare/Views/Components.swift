import SwiftUI

/// Big minus / value / plus control for millilitres or ounces.
/// The value is always stored in millilitres.
struct AmountStepper: View {
    @Binding var ml: Double
    let unit: VolumeUnit
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            roundButton("plus") { change(by: unit.step) }
            VStack(spacing: 2) {
                Text(Fmt.number(unit.fromML(ml)))
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                Text(unit.title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            roundButton("minus") { change(by: -unit.step) }
        }
    }

    private func change(by delta: Double) {
        let next = max(0, unit.fromML(ml) + delta)
        withAnimation { ml = unit.toML(next) }
    }

    private func roundButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title.bold())
                .foregroundStyle(color)
                .frame(width: 72, height: 72)
                .background(Circle().fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
    }
}

/// Quick amount chips (e.g. ٣٠، ٦٠، ٩٠ مل).
struct QuickAmounts: View {
    @Binding var ml: Double
    let unit: VolumeUnit
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(unit.quickAmounts, id: \.self) { value in
                let selected = abs(unit.fromML(ml) - value) < 0.01
                Button {
                    withAnimation { ml = unit.toML(value) }
                } label: {
                    Text(Fmt.number(value))
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(selected ? Color.white : color)
                        .background(RoundedRectangle(cornerRadius: 14).fill(selected ? color : color.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// "When" row; defaults to now and can be moved back for late logging.
struct TimeRow: View {
    @Binding var date: Date

    var body: some View {
        DatePicker("الوقت", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
            .font(.headline)
            .cardStyle()
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Wraps a logging form in a navigation bar with a close button and a large save button at the bottom.
struct LogSheet<Content: View>: View {
    let title: String
    let color: Color
    let saveTitle: String
    let canSave: Bool
    let onSave: () -> Void
    @ViewBuilder let content: Content
    // Not private, so the memberwise initializer stays internal.
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) { content }
                    .padding(16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave()
                    dismiss()
                } label: {
                    Label(saveTitle, systemImage: "checkmark")
                }
                .buttonStyle(BigButtonStyle(color: color))
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
                .padding(16)
                .background(.bar)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
    }
}

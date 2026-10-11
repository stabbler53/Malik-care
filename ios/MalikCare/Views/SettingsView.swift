import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Keys.babyName) private var babyName = Defaults.babyName
    @AppStorage(Keys.motherName) private var motherName = Defaults.motherName
    @AppStorage(Keys.birthDate) private var birthDate = 0.0
    @AppStorage(Keys.volumeUnit) private var unitRaw = VolumeUnit.ml.rawValue
    @AppStorage(Keys.nightMode) private var nightMode = NightMode.system.rawValue

    private var birthBinding: Binding<Date> {
        Binding(
            get: { birthDate > 0 ? Date(timeIntervalSince1970: birthDate) : .now },
            set: { birthDate = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("الطفل") {
                    TextField("اسم الطفل", text: $babyName)
                    DatePicker("تاريخ الميلاد", selection: birthBinding, in: ...Date.now, displayedComponents: .date)
                }
                Section("الأم") {
                    TextField("اسم الأم", text: $motherName)
                }
                Section("وحدة الكمية") {
                    Picker("الوحدة", selection: $unitRaw) {
                        ForEach(VolumeUnit.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Picker("المظهر", selection: $nightMode) {
                        ForEach(NightMode.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("الوضع الليلي")
                } footer: {
                    Text("الوضع الليلي أسود بالكامل وخافت حتى لا يزعج الإضاءة أثناء رضعات الليل.")
                }
                Section {
                    Label("كل البيانات محفوظة على هذا الجهاز فقط ولا تُرسل إلى أي مكان.", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
    }
}

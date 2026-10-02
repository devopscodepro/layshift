import SwiftUI

struct ShortcutsSettingsView: View {
    @ObservedObject var sources: InputSourceStore

    var body: some View {
        Form {
            Section {
                ForEach(sources.sources) { source in
                    LabeledContent {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: 8) {
                            if let icon = sources.icon(for: source) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            Text(source.name)
                        }
                    }
                }
            } header: {
                Text("Switch to a layout")
            } footer: {
                Text("Layouts come from System Settings → Keyboard → Input Sources.")
            }

            Section {
                LabeledContent("Next layout") {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Cycle")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { sources.refresh() }
    }
}

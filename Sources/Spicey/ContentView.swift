import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "display")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Spicey")
                .font(.title2.bold())

            Text("Open a Proxmox console (.vv) file, or drag one here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open .vv File…") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [UTType(filenameExtension: "vv") ?? .data]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url {
                    openVVFile(url)
                }
            }
        }
        .padding(40)
        .frame(minWidth: 360, minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDropTargeted ? Color.accentColor : .clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { openVVFile(url) }
            }
            return true
        }
    }
}

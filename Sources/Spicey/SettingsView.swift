import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.fullscreenOnConnect) private var fullscreenOnConnect = false
    @AppStorage(SettingsKey.scaleToWindow) private var scaleToWindow = true

    var body: some View {
        Form {
            Toggle("Open in fullscreen", isOn: $fullscreenOnConnect)
            Toggle("Scale display to fit window", isOn: $scaleToWindow)
        }
        .padding(20)
        .frame(width: 320)
    }
}

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Finder hands us .vv files here — both on first launch (double-click)
    /// and on subsequent opens while already running.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            openVVFile(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

func openVVFile(_ url: URL) {
    do {
        let vv = try VVFile.read(at: url)
        guard vv.type.lowercased() == "spice" else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Unsupported console type"
            alert.informativeText = "Spicey only supports SPICE consoles; this file is type \"\(vv.type)\"."
            alert.runModal()
            return
        }
        let defaults = UserDefaults.standard
        HelperLauncher.open(
            url,
            fullscreen: defaults.bool(forKey: SettingsKey.fullscreenOnConnect),
            scale: defaults.object(forKey: SettingsKey.scaleToWindow) == nil
                ? true
                : defaults.bool(forKey: SettingsKey.scaleToWindow)
        )
    } catch {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn't open that file"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

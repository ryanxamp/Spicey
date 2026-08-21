import AppKit

/// Spawns the bundled spicey-display helper for a .vv file and surfaces
/// any early failure (bad ticket, unreachable proxy, TLS error, ...) as a
/// native alert instead of leaving the user staring at nothing.
enum HelperLauncher {
    struct NotBundled: LocalizedError {
        var errorDescription: String? { "spicey-display helper is missing from the app bundle." }
    }

    static func open(_ vvURL: URL, fullscreen: Bool, scale: Bool) {
        guard let helperPath = Bundle.main.path(forResource: "spicey-display", ofType: nil) else {
            presentError(NotBundled())
            return
        }

        var args = [vvURL.path]
        if fullscreen { args.append("--fullscreen") }
        if !scale { args.append("--no-scale") }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: helperPath)
        process.arguments = args

        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        var stderrData = Data()
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            stderrData.append(handle.availableData)
        }

        process.terminationHandler = { proc in
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            guard proc.terminationStatus != 0 else { return }
            let message = String(data: stderrData, encoding: .utf8)?
                .split(separator: "\n")
                .last(where: { $0.hasPrefix("spicey-display:") })
                .map(String.init)
                ?? "The connection closed unexpectedly (exit code \(proc.terminationStatus))."
            DispatchQueue.main.async {
                presentMessage(message)
            }
        }

        do {
            try process.run()
        } catch {
            presentError(error)
        }
    }

    private static func presentError(_ error: Error) {
        presentMessage(error.localizedDescription)
    }

    private static func presentMessage(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn't open the console"
        alert.informativeText = message
        alert.runModal()
    }
}

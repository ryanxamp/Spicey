import Foundation

/// Minimal read of a Proxmox virt-viewer (.vv) file — just enough to show
/// a title and validate the type before handing the whole file to the
/// spicey-display helper, which does the real parsing.
struct VVFile {
    let title: String
    let type: String

    enum ParseError: LocalizedError {
        case notReadable
        case missingSection

        var errorDescription: String? {
            switch self {
            case .notReadable: return "Couldn't read that file."
            case .missingSection: return "That doesn't look like a virt-viewer (.vv) file."
            }
        }
    }

    static func read(at url: URL) throws -> VVFile {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            throw ParseError.notReadable
        }

        var inSection = false
        var values: [String: String] = [:]
        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                inSection = (line == "[virt-viewer]")
                continue
            }
            guard inSection, let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[line.startIndex..<eq])
            let value = String(line[line.index(after: eq)...])
            values[key] = value
        }

        guard !values.isEmpty else { throw ParseError.missingSection }
        return VVFile(
            title: values["title"] ?? url.deletingPathExtension().lastPathComponent,
            type: values["type"] ?? "spice"
        )
    }
}

import CoreGraphics
import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "zones")

/// Persists per-monitor cycle preset selections to
/// `~/Library/Application Support/WindowLatch/zones.json`. Keyed by
/// `CGDirectDisplayID` (stable across reboots for built-in displays;
/// for external displays it's stable for the same physical port).
@Observable
@MainActor
final class ZoneStore {
    static let shared = ZoneStore()

    private(set) var presets: [CGDirectDisplayID: CyclePreset]
    var onChange: (() -> Void)?

    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.presets = Self.load(from: self.fileURL)
    }

    func preset(for displayID: CGDirectDisplayID) -> CyclePreset {
        presets[displayID] ?? .default
    }

    func setPreset(_ preset: CyclePreset, for displayID: CGDirectDisplayID) {
        guard presets[displayID] != preset else { return }
        presets[displayID] = preset
        save()
        onChange?()
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var presets: [String: CyclePreset]
    }

    private static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)) ?? fm.homeDirectoryForCurrentUser
        let dir = base.appendingPathComponent("WindowLatch", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("zones.json")
    }

    private static func load(from url: URL) -> [CGDirectDisplayID: CyclePreset] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            let decoded = try JSONDecoder().decode(Persisted.self, from: data)
            var out: [CGDirectDisplayID: CyclePreset] = [:]
            for (k, v) in decoded.presets {
                if let id = UInt32(k) { out[id] = v }
            }
            return out
        } catch {
            log.error("Failed to decode zones.json: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }

    private func save() {
        let serialised = Persisted(
            presets: Dictionary(uniqueKeysWithValues: presets.map { (String($0.key), $0.value) })
        )
        do {
            let data = try JSONEncoder().encode(serialised)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log.error("Failed to write zones.json: \(error.localizedDescription, privacy: .public)")
        }
    }
}

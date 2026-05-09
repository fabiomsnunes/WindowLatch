import CoreGraphics
import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "com.fabiomsnunes.WindowLatch", category: "zones")

/// Per-monitor selection of enabled `ZoneGroup`s, persisted to
/// `~/Library/Application Support/WindowLatch/zones.json`. Keyed by
/// `CGDirectDisplayID` (stable across reboots for built-in displays;
/// for external displays it's stable for the same physical port).
@Observable
@MainActor
final class ZoneStore {
    static let shared = ZoneStore()

    private(set) var groups: [CGDirectDisplayID: Set<ZoneGroup>]

    @ObservationIgnored private var observers: [() -> Void] = []
    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.groups = Self.load(from: self.fileURL)
    }

    func addObserver(_ block: @escaping () -> Void) {
        observers.append(block)
    }

    private func notify() {
        observers.forEach { $0() }
    }

    func enabledGroups(for displayID: CGDirectDisplayID) -> Set<ZoneGroup> {
        groups[displayID] ?? ZoneGroup.defaults
    }

    func setGroup(_ group: ZoneGroup, enabled: Bool, for displayID: CGDirectDisplayID) {
        var current = enabledGroups(for: displayID)
        if enabled {
            current.insert(group)
        } else {
            current.remove(group)
        }
        guard groups[displayID] != current else { return }
        groups[displayID] = current
        save()
        notify()
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var groups: [String: [ZoneGroup]]
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

    private static func load(from url: URL) -> [CGDirectDisplayID: Set<ZoneGroup>] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            let decoded = try JSONDecoder().decode(Persisted.self, from: data)
            var out: [CGDirectDisplayID: Set<ZoneGroup>] = [:]
            for (k, v) in decoded.groups {
                if let id = UInt32(k) { out[id] = Set(v) }
            }
            return out
        } catch {
            log.error("Failed to decode zones.json: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }

    private func save() {
        let serialised = Persisted(
            groups: Dictionary(uniqueKeysWithValues: groups.map { (String($0.key), Array($0.value)) })
        )
        do {
            let data = try JSONEncoder().encode(serialised)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log.error("Failed to write zones.json: \(error.localizedDescription, privacy: .public)")
        }
    }
}

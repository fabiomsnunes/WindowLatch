import CoreGraphics
import Foundation
import Testing
@testable import WindowLatch

@MainActor
struct ZoneStoreTests {
    private func tempURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WindowLatchTests", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("zones-\(UUID().uuidString).json")
    }

    @Test
    func roundTrip_persistsGroupsAcrossInstances() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let storeA = ZoneStore(fileURL: url)
        storeA.setGroup(.quarters, enabled: false, for: 1)
        storeA.setGroup(.thirdsHorizontal, enabled: false, for: 1)
        storeA.setGroup(.halvesVertical, enabled: false, for: 2)

        let storeB = ZoneStore(fileURL: url)
        let display1 = storeB.enabledGroups(for: 1)
        let display2 = storeB.enabledGroups(for: 2)

        #expect(!display1.contains(.quarters))
        #expect(!display1.contains(.thirdsHorizontal))
        #expect(display1.contains(.halvesHorizontal))
        #expect(!display2.contains(.halvesVertical))
        #expect(display2.contains(.quarters))
    }

    @Test
    func unconfiguredDisplay_returnsDefaults() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ZoneStore(fileURL: url)
        #expect(store.enabledGroups(for: 99) == ZoneGroup.defaults)
    }

    @Test
    func corruptJSON_fallsBackToEmpty() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try! "{ this is not json".data(using: .utf8)!.write(to: url)

        let store = ZoneStore(fileURL: url)
        // Corrupt file → load returns empty dict → unconfigured displays return defaults.
        #expect(store.enabledGroups(for: 1) == ZoneGroup.defaults)
    }

    @Test
    func setGroup_writesToDiskImmediately() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ZoneStore(fileURL: url)
        store.setGroup(.quarters, enabled: false, for: 42)

        // File exists and is valid JSON containing display 42 mapping.
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let groups = json["groups"] as! [String: [String]]
        #expect(groups["42"] != nil)
        #expect(!(groups["42"] ?? []).contains("quarters"))
    }

    @Test
    func setGroup_isIdempotentOnceMaterialised() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ZoneStore(fileURL: url)
        // First call materialises defaults for display 7 → writes file.
        store.setGroup(.quarters, enabled: true, for: 7)
        let mtime1 = try! FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as! Date
        // Second call with same value → set comparison short-circuits, no rewrite.
        Thread.sleep(forTimeInterval: 0.05)
        store.setGroup(.quarters, enabled: true, for: 7)
        let mtime2 = try! FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as! Date
        #expect(mtime1 == mtime2)
    }

    @Test
    func observer_firesOnChange() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ZoneStore(fileURL: url)

        var fired = 0
        store.addObserver { fired += 1 }

        store.setGroup(.quarters, enabled: false, for: 1) // change → notify
        store.setGroup(.quarters, enabled: false, for: 1) // no-op, no notify
        store.setGroup(.quarters, enabled: true, for: 1) // change → notify

        #expect(fired == 2)
    }
}

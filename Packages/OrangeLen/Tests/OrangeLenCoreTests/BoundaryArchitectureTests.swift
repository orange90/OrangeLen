import XCTest
@testable import OrangeLenCore

final class BoundaryArchitectureTests: XCTestCase {
    func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true); return url
    }
    func testIndependentSettingsMergeAndClearInvalidatesOpenSessions() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        let suite = "boundary." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let a = SettingsStore(group: nil, defaults: defaults, directory: root)
        let b = SettingsStore(group: nil, defaults: defaults, directory: root)
        var baseline = ReaderSettings(); baseline.remember = true; a.save(baseline)
        var first = baseline; first.theme = "Dark"; a.update(from: baseline, to: first)
        var second = baseline; second.codeSize = 22; b.update(from: baseline, to: second)
        XCTAssertEqual(a.load().theme, "Dark"); XCTAssertEqual(a.load().codeSize, 22)
        let old = a.readingGeneration; XCTAssertEqual(old, b.readingGeneration)
        let file = root.appendingPathComponent("sample.md")
        a.remember(file, revision: "1", offset: 6, generation: old)
        XCTAssertEqual(b.restore(file, revision: "1"), 6)
        b.clear(); a.remember(file, revision: "1", offset: 9, generation: old)
        XCTAssertNil(a.restore(file, revision: "1")); XCTAssertNotEqual(old, a.readingGeneration)
        a.remember(file, revision: "1", offset: 11, generation: a.readingGeneration)
        XCTAssertEqual(b.restore(file, revision: "1"), 11)
        XCTAssertEqual(b.load().theme, "Dark")
    }
    func testFolderContinuationRejectsChangedDirectory() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        for name in ["a", "b", "c"] { try Data().write(to: root.appendingPathComponent(name)) }
        var limits = PreviewLimits(); limits.directoryBatch = 1
        let first = try FolderLoader.page(root, root: root, limits: limits)
        XCTAssertNotNil(first.nextOffset)
        try Data().write(to: root.appendingPathComponent("new"))
        XCTAssertThrowsError(try FolderLoader.page(root, root: root, offset: first.nextOffset!, limits: limits, expectedRevision: first.revision)) { error in
            guard case PreviewError.changed = error else { return XCTFail("unexpected \(error)") }
        }
        XCTAssertEqual(try FolderLoader.page(root, root: root).entries.count, 4)
    }
    func testGrantFailsClosedAcrossClockRollbackSleepRebootAndRenewal() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("a.md"); try Data().write(to: file)
        let store = ImageDirectoryGrant(directory: root.appendingPathComponent("grants"), group: nil)
        let now = Date(), owner = UUID(), renewed = UUID()
        try store.publish(root, document: file, revision: "a", owner: owner, now: now, continuous: 100, boot: "boot")
        XCTAssertNotNil(store.resolve(document: file, revision: "a", now: now, continuous: 100, boot: "boot"))
        XCTAssertNil(store.resolve(document: file, revision: "a", now: now.addingTimeInterval(-1), continuous: 101, boot: "boot"))
        XCTAssertNil(store.resolve(document: file, revision: "a", now: now, continuous: 131, boot: "boot"))
        XCTAssertNil(store.resolve(document: file, revision: "a", now: now, continuous: 101, boot: "reboot"))
        try store.publish(root, document: file, revision: "a", owner: renewed, now: now, continuous: 101, boot: "boot")
        store.remove(document: file, owner: owner)
        XCTAssertEqual(store.resolve(document: file, revision: "a", now: now, continuous: 102, boot: "boot")?.owner, renewed)
        store.remove(document: file, owner: renewed)
        XCTAssertNil(store.resolve(document: file, revision: "a", now: now, continuous: 102, boot: "boot"))
    }
    func testTypedCopyDistinguishesNullBlobsAndEscapesTSV() {
        XCTAssertEqual(DatabaseDocument.Cell.null.sqlLiteral, "NULL")
        XCTAssertEqual(DatabaseDocument.Cell.text("NULL").sqlLiteral, "'NULL'")
        XCTAssertEqual(DatabaseDocument.Cell.blob(Data([0, 255])).sqlLiteral, "X'00FF'")
        XCTAssertEqual(DatabaseDocument.Cell.text("[BLOB 2 bytes]").sqlLiteral, "'[BLOB 2 bytes]'")
        XCTAssertEqual(DatabaseDocument.Cell.invalidText(Data([255])).sqlLiteral, "CAST(X'FF' AS TEXT)")
        XCTAssertEqual(DatabaseDocument.Cell.text("\0").sqlLiteral, "CAST(X'00' AS TEXT)")
        XCTAssertEqual(DatabaseDocument.tsvField("a\tb\n\"c\""), "\"a\tb\n\"\"c\"\"\"")
    }
    func testQueueRejectsOverloadAndImmediatelyReleasesCancelledPendingPayload() async {
        final class Payload {}
        let queue = PreviewWorkQueue(name: "test.boundary", concurrency: 1, pendingLimit: 1)
        let gate = DispatchSemaphore(value: 0), started = DispatchSemaphore(value: 0)
        let active = expectation(description: "active"), cancelled = expectation(description: "cancelled"), rejected = expectation(description: "rejected")
        queue.submit(cancellation: Cancellation(), work: { started.signal(); _ = gate.wait(timeout: .now() + 3) }, completion: { _ in active.fulfill() })
        XCTAssertEqual(started.wait(timeout: .now() + 1), .success)
        var payload: Payload? = Payload(); weak var weakPayload = payload
        let token = Cancellation()
        queue.submit(cancellation: token, work: { [value = payload!] in _ = value; XCTFail("cancelled work ran") }, completion: { result in
            if case .failure(let error) = result { XCTAssertTrue(error is CancellationError) } else { XCTFail("not cancelled") }; cancelled.fulfill()
        })
        payload = nil
        queue.submit(cancellation: Cancellation(), work: { XCTFail("overloaded work ran") }, completion: { result in
            if case .failure(let error) = result { guard case PreviewError.limit = error else { return XCTFail("wrong overload") } } else { XCTFail("not rejected") }; rejected.fulfill()
        })
        token.cancel(); XCTAssertNil(weakPayload)
        gate.signal(); await fulfillment(of: [active, cancelled, rejected], timeout: 4)
    }
    @MainActor func testProgressCoalescesWhileMainQueueIsBusy() async {
        let received = expectation(description: "latest"); received.expectedFulfillmentCount = 1
        let delivery = LatestDelivery<Int> { value in XCTAssertEqual(value, 999); received.fulfill() }
        for n in 0..<1000 { delivery.send(n) }
        await fulfillment(of: [received], timeout: 1)
    }
    func testMediaDescriptorDetectsReplacementAndRejectsLinks() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("sample.mp4"), link = root.appendingPathComponent("link.mp4")
        try Data([1, 2, 3]).write(to: file)
        let media = try ScopedMediaFile(file, root: root)
        XCTAssertEqual(try media.read(offset: 1, count: 2, cancellation: Cancellation()), Data([2, 3]))
        try Data([4, 5, 6]).write(to: file, options: .atomic)
        XCTAssertThrowsError(try media.read(offset: 0, count: 3, cancellation: Cancellation()))
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        XCTAssertThrowsError(try ScopedMediaFile(link, root: root))
        let cancelled = Cancellation(); cancelled.cancel()
        XCTAssertThrowsError(try media.read(offset: 0, count: 1, cancellation: cancelled))
    }
    func testNativePayloadRejectsOversizedAndInvalidRanges() throws {
        XCTAssertThrowsError(try NativeDocumentPayload(text: "abc", spans: [.init(location: 2, length: Int.max, size: 14, bold: false, italic: false)]).validate())
        XCTAssertThrowsError(try NativeDocumentPayload(text: "abc", spans: [.init(location: 0, length: 1, size: .infinity, bold: false, italic: false)]).validate())
        XCTAssertThrowsError(try NativeDocumentPayload(text: String(repeating: "a", count: 1_000_001), spans: []).validate())
    }
    func testUTF16PageBoundaryBOMsAndSurrogatesRemainContent() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        for littleEndian in [true, false] {
            let original = "1234567\u{FEFF}😀end"
            var data = Data(littleEndian ? [0xFF, 0xFE] : [0xFE, 0xFF])
            for unit in original.utf16 { data.append(contentsOf: littleEndian ? [UInt8(unit & 255), UInt8(unit >> 8)] : [UInt8(unit >> 8), UInt8(unit & 255)]) }
            let file = root.appendingPathComponent("test.txt"); try data.write(to: file)
            let first = try AccessBroker.readPreview(file, pageBytes: 16, fullReadThreshold: 0)
            let second = try AccessBroker.readPreview(file, byteOffset: first.byteCount, pageBytes: 16, fullReadThreshold: 0)
            XCTAssertEqual(first.text + second.text, original); XCTAssertTrue(second.text.hasPrefix("\u{FEFF}"))
        }
    }

    func testPreferencesMergeWhenSharedFilesystemIsUnavailable() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        let blocked = root.appendingPathComponent("not-a-directory"); try Data([1]).write(to: blocked)
        let suite = "boundary." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let a = SettingsStore(group: nil, defaults: defaults, directory: blocked)
        let b = SettingsStore(group: nil, defaults: defaults, directory: root.appendingPathComponent("second"))
        let baseline = ReaderSettings(); var x = baseline; x.theme = "Dark"
        a.update(from: baseline, to: x)
        var y = baseline; y.codeSize = 1000; b.update(from: baseline, to: y)
        XCTAssertEqual(a.load().theme, "Dark"); XCTAssertEqual(a.load().codeSize, 32)
        var remembering = b.load(); remembering.remember = true; b.save(remembering)
        let file = root.appendingPathComponent("a.md"), generation = b.readingGeneration
        b.remember(file, revision: "a", offset: 10, generation: generation)
        XCTAssertEqual(b.restore(file, revision: "a"), 10)
        a.clear(); b.remember(file, revision: "a", offset: 20, generation: generation)
        XCTAssertNil(b.restore(file, revision: "a"))
    }

    func testSharedWorkerSlotsReleaseAndUnavailableFilesystemFallsBack() throws {
        let root = try temporaryDirectory(); defer { try? FileManager.default.removeItem(at: root) }
        var leases = try (0..<4).map { _ in try PreviewResourceLease(lane: "parse", sharedDirectory: root) }
        XCTAssertThrowsError(try PreviewResourceLease(lane: "parse", sharedDirectory: root))
        leases.removeLast()
        XCTAssertNoThrow(try PreviewResourceLease(lane: "parse", sharedDirectory: root))
        withExtendedLifetime(leases) {}
        let blocked = root.appendingPathComponent("file"); try Data([1]).write(to: blocked)
        XCTAssertNoThrow(try PreviewResourceLease(lane: "parse", sharedDirectory: blocked.appendingPathComponent("workers")))
    }

}

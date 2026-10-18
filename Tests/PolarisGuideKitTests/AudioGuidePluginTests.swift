import AVFoundation
import UIKit
import XCTest
@testable import PolarisGuideKit

final class AudioGuidePluginTests: XCTestCase {
    private var audioURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PolarisGuideKit-\(UUID().uuidString).wav")
        try silentWAV().write(to: audioURL)
    }

    override func tearDownWithError() throws {
        if let audioURL = audioURL {
            try FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
        try super.tearDownWithError()
    }

    func testNaturalCompletionCallbackCanStartNextItem() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let firstBuddy = AudioBuddyView()
        let nextBuddy = AudioBuddyView()
        let firstContext = context(buddy: firstBuddy)
        let nextContext = context(buddy: nextBuddy)
        defer {
            firstBuddy.onStop = nil
            plugin.handle(.guideWillHide, context: nextContext)
        }
        let completed = expectation(description: "Natural completion delivered")
        var nextItem: AVPlayerItem?

        firstBuddy.onStop = { didPlayToEnd in
            XCTAssertTrue(didPlayToEnd)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(player.currentItem)
            // This is the event sequence produced when requestNext() changes steps.
            plugin.handle(.stepWillHide, context: firstContext)
            plugin.handle(.stepDidShow, context: nextContext)
            nextItem = player.currentItem
            completed.fulfill()
        }

        plugin.handle(.stepDidShow, context: firstContext)
        let firstItem = try XCTUnwrap(player.currentItem)
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: firstItem)
        wait(for: [completed], timeout: 3)

        XCTAssertNotNil(nextItem)
        XCTAssertTrue(player.currentItem === nextItem)
        XCTAssertEqual(firstBuddy.stopEvents, [true])
        XCTAssertEqual(nextBuddy.startCount, 1)
        XCTAssertTrue(nextBuddy.stopEvents.isEmpty)
    }

    func testFailureCallbackCanStartNextItemWithoutClearingIt() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let firstBuddy = AudioBuddyView()
        let nextBuddy = AudioBuddyView()
        let firstContext = context(buddy: firstBuddy)
        let nextContext = context(buddy: nextBuddy)
        defer {
            firstBuddy.onFail = nil
            plugin.handle(.guideWillHide, context: nextContext)
        }
        let failed = expectation(description: "Playback failure delivered")
        let expectedError = NSError(domain: "AudioGuidePluginTests", code: 42)
        var nextItem: AVPlayerItem?

        firstBuddy.onFail = { error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(player.currentItem)
            XCTAssertEqual((error as NSError).domain, expectedError.domain)
            XCTAssertEqual((error as NSError).code, expectedError.code)
            plugin.handle(.stepDidShow, context: nextContext)
            nextItem = player.currentItem
            failed.fulfill()
        }

        plugin.handle(.stepDidShow, context: firstContext)
        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: try XCTUnwrap(player.currentItem),
            userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: expectedError]
        )
        wait(for: [failed], timeout: 3)

        XCTAssertNotNil(nextItem)
        XCTAssertTrue(player.currentItem === nextItem)
        XCTAssertTrue(firstBuddy.stopEvents.isEmpty)
        XCTAssertEqual(firstBuddy.failureCount, 1)
        XCTAssertEqual(nextBuddy.startCount, 1)
        XCTAssertTrue(nextBuddy.stopEvents.isEmpty)
    }

    func testInitialMediaLoadFailureIsReportedOnceOnMainThread() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let buddy = AudioBuddyView()
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).mp3")
        let missingContext = context(buddy: buddy, url: missingURL)
        defer {
            buddy.onFail = nil
            plugin.handle(.guideWillHide, context: missingContext)
        }
        let failed = expectation(description: "Initial load failure delivered")

        buddy.onFail = { _ in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(player.currentItem)
            failed.fulfill()
        }
        plugin.handle(.stepDidShow, context: missingContext)
        wait(for: [failed], timeout: 10)
        drainMainQueue()

        XCTAssertEqual(buddy.startCount, 1)
        XCTAssertEqual(buddy.failureCount, 1)
        XCTAssertTrue(buddy.stopEvents.isEmpty)
    }

    func testQueuedOldItemNotificationsDoNotStopOrFailNewItem() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let firstBuddy = AudioBuddyView()
        let nextBuddy = AudioBuddyView()
        let firstContext = context(buddy: firstBuddy)
        let nextContext = context(buddy: nextBuddy)
        defer { plugin.handle(.guideWillHide, context: nextContext) }

        plugin.handle(.stepDidShow, context: firstContext)
        let oldItem = try XCTUnwrap(player.currentItem)
        // Queue both callbacks before replacing the item. Removing their observers
        // cannot retract work that has already been enqueued on the main queue.
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: oldItem)
        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: oldItem,
            userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: NSError(domain: "OldItem", code: 1)]
        )
        plugin.handle(.stepDidShow, context: nextContext)
        let nextItem = try XCTUnwrap(player.currentItem)
        drainMainQueue()

        XCTAssertTrue(player.currentItem === nextItem)
        XCTAssertEqual(firstBuddy.stopEvents, [false])
        XCTAssertEqual(firstBuddy.failureCount, 0)
        XCTAssertEqual(nextBuddy.startCount, 1)
        XCTAssertTrue(nextBuddy.stopEvents.isEmpty)
        XCTAssertEqual(nextBuddy.failureCount, 0)
    }

    func testStopCallbackCanReplaceThePendingStep() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let firstBuddy = AudioBuddyView()
        let supersededBuddy = AudioBuddyView()
        let chosenBuddy = AudioBuddyView()
        let firstContext = context(buddy: firstBuddy)
        let supersededContext = context(buddy: supersededBuddy)
        let chosenContext = context(buddy: chosenBuddy)
        defer {
            firstBuddy.onStop = nil
            plugin.handle(.guideWillHide, context: chosenContext)
        }
        var chosenItem: AVPlayerItem?

        firstBuddy.onStop = { _ in
            XCTAssertNil(player.currentItem)
            plugin.handle(.stepDidShow, context: chosenContext)
            chosenItem = player.currentItem
        }
        plugin.handle(.stepDidShow, context: firstContext)
        plugin.handle(.stepDidShow, context: supersededContext)

        XCTAssertNotNil(chosenItem)
        XCTAssertTrue(player.currentItem === chosenItem)
        XCTAssertEqual(supersededBuddy.startCount, 0)
        XCTAssertEqual(chosenBuddy.startCount, 1)
        XCTAssertEqual(firstBuddy.stopEvents, [false])
    }

    func testReleasingGuideStopsRetainedAudioPluginWithoutBuddyCallbacks() throws {
        let host = UIView()
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let buddy = AudioBuddyView()
        let step = context(buddy: buddy).step
        weak var released: GuideController?

        try autoreleasepool {
            let guide = GuideController(hostView: host, steps: [step], plugins: [plugin])
            released = guide
            buddy.onStop = { [unowned guide] _ in
                _ = guide.currentStepIndex
                XCTFail("Deinit must not send audio stop callbacks")
            }
            buddy.onFail = { [unowned guide] _ in
                _ = guide.currentStepIndex
                XCTFail("Queued audio callbacks must be invalidated during deinit")
            }
            XCTAssertTrue(guide.show())
            let item = try XCTUnwrap(player.currentItem)
            NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: item)
            NotificationCenter.default.post(
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: NSError(domain: "OldItem", code: 1)]
            )
        }

        XCTAssertNil(released)
        XCTAssertNil(player.currentItem)
        XCTAssertEqual(player.rate, 0)
        drainMainQueue()
        XCTAssertEqual(buddy.startCount, 1)
        XCTAssertTrue(buddy.stopEvents.isEmpty)
        XCTAssertEqual(buddy.failureCount, 0)
    }

    func testAudioTeardownIsIdempotentAndPluginCanBeReused() throws {
        let plugin = AudioGuidePlugin()
        let player = try audioPlayer(in: plugin)
        let firstBuddy = AudioBuddyView()
        plugin.handle(.stepDidShow, context: context(buddy: firstBuddy))
        XCTAssertNotNil(player.currentItem)
        plugin.tearDown()
        plugin.tearDown()
        XCTAssertNil(player.currentItem)
        XCTAssertTrue(firstBuddy.stopEvents.isEmpty)

        let nextBuddy = AudioBuddyView()
        let nextContext = context(buddy: nextBuddy)
        plugin.handle(.stepDidShow, context: nextContext)
        XCTAssertNotNil(player.currentItem)
        XCTAssertEqual(nextBuddy.startCount, 1)
        plugin.handle(.guideWillHide, context: nextContext)
        XCTAssertNil(player.currentItem)
        XCTAssertEqual(nextBuddy.stopEvents, [false])
    }

    private func audioPlayer(in plugin: AudioGuidePlugin) throws -> AVPlayer {
        try XCTUnwrap(Mirror(reflecting: plugin).children.first {
            $0.label == "audioPlayer"
        }?.value as? AVPlayer)
    }

    private func context(buddy: AudioBuddyView, url: URL? = nil) -> GuideStepContext {
        let step = GuideStep()
        step.buddyView = buddy
        step.addAttachment(GuideAudioAttachment(url: url ?? audioURL))
        return GuideStepContext(
            hostView: nil,
            containerView: nil,
            overlayView: nil,
            focusView: nil,
            buddyView: buddy,
            step: step,
            stepIndex: 0
        )
    }

    private func drainMainQueue() {
        let drained = expectation(description: "Pending playback callbacks processed")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 3)
    }

    private func silentWAV() -> Data {
        // A valid, long-lived local item avoids network and missing-file failures
        // in tests that exercise callback ordering rather than media loading.
        let sampleRate: UInt32 = 8_000
        let byteCount: UInt32 = sampleRate * 2 * 30
        var data = Data("RIFF".utf8)
        func append<T: FixedWidthInteger>(_ value: T) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }
        append(byteCount + 36)
        data.append(Data("WAVEfmt ".utf8))
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(sampleRate)
        append(sampleRate * 2)
        append(UInt16(2))
        append(UInt16(16))
        data.append(Data("data".utf8))
        append(byteCount)
        data.append(Data(count: Int(byteCount)))
        return data
    }
}

private final class AudioBuddyView: GuideBuddyView, GuideAudioEventReceiving {
    var startCount = 0
    var stopEvents: [Bool] = []
    var failureCount = 0
    var onStop: ((Bool) -> Void)?
    var onFail: ((Error) -> Void)?

    func guideAudioDidStart() {
        startCount += 1
    }

    func guideAudioDidStop(didPlayToEnd: Bool) {
        stopEvents.append(didPlayToEnd)
        onStop?(didPlayToEnd)
    }

    func guideAudioDidFail(_ error: Error) {
        failureCount += 1
        onFail?(error)
    }
}
